<?php

namespace App\Http\Controllers;

use App\Models\Docente;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use App\Models\CentroDocente;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;


class AltaDocenteController extends Controller
{
    public function create()
    {
        $centro = Auth::user()->centro;
        $modulosPorCiclo = \Illuminate\Support\Facades\DB::table('ciclos')
            ->join('ciclo_modulo', 'ciclos.id_ciclo', '=', 'ciclo_modulo.id_ciclo')
            ->join('modulos', 'ciclo_modulo.id_modulo', '=', 'modulos.id_modulo')
            ->select('ciclos.nombre as nombre_ciclo', 'modulos.*')
            ->get()
            ->groupBy('nombre_ciclo'); // Esto los agrupa automáticamente por el nombre del ciclo
        return view('alta_docente', compact('centro', 'modulosPorCiclo'));
    }

    /**
     * Normaliza nombres quitando caracteres prohibidos y poniendo mayúsculas.
     */
    private function normalizarNombreYApellido($string) {
        // Primero eliminamos los caracteres "º" y "."
        $limpio = str_replace(['º', '.'], '', $string);

        return mb_convert_case(mb_strtolower($limpio, 'UTF-8'), MB_CASE_TITLE, 'UTF-8');
    }


    public function store(Request $request)
    {
        // 1. Validamos que el profesor esté y que haya al menos un módulo seleccionado
        $request->validate([
            'dni' => 'required',
            'modulos' => 'required|array|min:1', // Obligamos a marcar al menos uno
        ]);

        $dni = strtoupper($request->dni);


        $validator = Validator::make($request->all(), [
           'dni' => [
                'required',
                'string',
                'max:10',
                'regex:/^(\d{8}|[XYZ]\d{7})[A-Z]$/i',
                function ($attribute, $value, $fail) use ($request) {
                    if (CentroDocente::where('dni', strtolower($value))
                        ->where('id_centro', $request->id_centro)
                        ->exists()) {
                        $fail('Este docente ya está asignado a este centro.');
                    }
                },
            ],

            //Comprueba si el email existe
            'email' => [
                'required',
                'email',
                function ($attribute, $value, $fail) {
                    if (CentroDocente::where('email', $value)->exists()) {
                        $fail('Este correo electrónico ya está registrado.');
                    }
                },
            ],

            'nombre' => 'required|string|max:255',
            'apellido' => 'required|string|max:255',
            'id_centro' => 'required|string',
            // TAREA E: Validamos el nuevo campo de formación
            'formacion' => 'nullable|boolean',
        ]);

        //Si da algun error
        if ($validator->fails()) {
            return redirect()->back()->withErrors($validator)->withInput();
        }

        DB::beginTransaction();

        try {
            // Buscar el docente existente por DNI
            $docente = Docente::where('dni', $dni)->first();

            // 2. ASIGNACIÓN MASIVA DE MÓDULOS
            // Primero borramos las asignaciones antiguas para no duplicar (si es necesario)
        DB::table('docente_modulo_ciclo')->where('dni', $dni)->delete();
            // Luego insertamos cada módulo seleccionado
            foreach ($request->modulos as $id_modulo) {
                DB::table('docente_modulo_ciclo')->insert([
                    'dni' => $dni,
                    'id_modulo' => $id_modulo,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            if ($docente) {
                // Si el nombre o apellido han cambiado, actualizarlos
                $nombreNuevo = $this->normalizarNombreYApellido($request->nombre);
                $apellidoNuevo = $this->normalizarNombreYApellido($request->apellido);

                $actualizado = false;

                if ($docente->nombre !== $nombreNuevo) {
                    $docente->nombre = $nombreNuevo;
                    $actualizado = true;
                }

                if ($docente->apellido !== $apellidoNuevo) {
                    $docente->apellido = $apellidoNuevo;
                    $actualizado = true;
                }

                if($docente->de_baja) {
                    $docente->de_baja = false;
                    $actualizado = true;
                }

                if ($actualizado) {
                    $docente->save();

                    // Comando moosh para actualizar el docente en Moodle ( Uso de escapehellarg para que los comandos sean seguros y no puedan poner algo malicioso los usuarios )
                    /*$command = "moosh user-update" .
                        " --firstname " . escapeshellarg($request->nombre) .
                        " --lastname " . escapeshellarg($request->apellido) .
                        " " . escapeshellarg($dni);

                    $this->ejecutarMoosh($command);*/
                }

            } else {
                // Si no existe, se crea
                $docente = Docente::create([
                    'dni' => $dni,
                    'nombre' => $this->normalizarNombreYApellido($request->nombre),
                    'apellido' => $this->normalizarNombreYApellido($request->apellido),
                    'formacion' => $request->boolean('formacion'), // Guardamos el booleano
                    'email_virtual' => $request->email,
                ]);

                // Comando moosh para crear nuevo usuario en Moodle ( Uso de escapehellarg para que los comandos sean seguros y no puedan poner algo malicioso los usuarios )
                /*$command = "moosh user-create" .
                    " --email " . escapeshellarg($request->email) .
                    " --password " . escapeshellarg($dni) . // DNI de contraseña
                    " --firstname " . escapeshellarg($request->nombre) .
                    " --lastname " . escapeshellarg($request->apellido) .
                    " " . escapeshellarg($dni);

                $this->ejecutarMoosh($command); */
            }

            // Asignar el docente al centro
            CentroDocente::create([
                'dni' => $dni,
                'id_centro' => $request->id_centro,
                'email' => $request->email,
            ]);

            DB::commit();

            return redirect()->route('dashboard')->with('alta_docente_correcto', 'Docente asignado correctamente.');

        } catch (\Exception $e) {
            DB::rollBack();
            return redirect()->back()->withErrors(['error' => 'Hubo un error al guardar el docente.' . $e->getMessage()])->withInput();
        }

    }

    //Comprueba si el dni existe para autocompletar los campos 'Nombre' y 'Apellido'
    public function comprobarDocente($dni)
    {
        $docente = Docente::where('dni', $dni)->first();

        $idCentro = Auth::user()->centro->id_centro;

        if ($docente) {
            return response()->json([
                'existe' => true,
                'nombre' => $docente->nombre,
                'apellido' => $docente->apellido,
                'email' => CentroDocente::where('dni', $dni)->where('id_centro', $idCentro)->value('email') // Obtener email del docente si existe
            ]);
        }

        return response()->json(['existe' => false]);
    }

    //Ejecuta & Control de errores para comandos moosh
    protected function ejecutarMoosh($command)
    {
        exec($command, $output, $status);
        if ($status !== 0) {
            Log::error("Fallo Moosh: " . implode("\n", $output));
            throw new \Exception("Fallo al ejecutar comando Moosh.");
        }
    }

}

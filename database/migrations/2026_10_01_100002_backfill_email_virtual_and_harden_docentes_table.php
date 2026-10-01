<?php

use App\Services\GeneradorEmailVirtualService;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // En producción hay filas con `email_virtual` NULL (alta manual antigua).
        // El alta de docente siempre genera el email virtual vía GeneradorEmailVirtualService,
        // así que el campo es NOT NULL por diseño: primero rellenamos los NULL
        // existentes y después endurecemos la restricción.
        $generador = app(GeneradorEmailVirtualService::class);

        DB::table('docentes')
            ->whereNull('email_virtual')
            ->orWhere('email_virtual', '')
            ->orderBy('id')
            ->chunkById(100, function ($docentes) use ($generador) {
                foreach ($docentes as $docente) {
                    $email = $generador->generarOObtenerExistente(
                        $docente->nombre,
                        $docente->apellido,
                        $docente->dni
                    );

                    DB::table('docentes')
                        ->where('id', $docente->id)
                        ->update(['email_virtual' => $email]);
                }
            });

        Schema::table('docentes', function (Blueprint $table) {
            $table->string('email_virtual')->nullable(false)->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('docentes', function (Blueprint $table) {
            $table->string('email_virtual')->nullable()->change();
        });
    }
};

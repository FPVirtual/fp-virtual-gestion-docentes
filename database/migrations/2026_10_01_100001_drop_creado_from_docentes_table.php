<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // La columna `creado` se añadió manualmente en producción y ningún código
        // la utiliza (ni modelo, ni controladores, ni vistas). Se elimina para
        // que el esquema del repo refleje la realidad.
        // Solo existe en producción: en un migrate:fresh la columna no está.
        if (Schema::hasColumn('docentes', 'creado')) {
            Schema::table('docentes', function (Blueprint $table) {
                $table->dropColumn('creado');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('docentes', function (Blueprint $table) {
            $table->boolean('creado')->default(false)->after('updated_at');
        });
    }
};

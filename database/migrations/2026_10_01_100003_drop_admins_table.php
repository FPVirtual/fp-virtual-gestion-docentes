<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Tabla legacy del antiguo guard `admin`, eliminada en la unificación de
        // autenticación (PR #73). Su migración original ya no está en el repo,
        // así que la tabla quedaría huérfana en producción al desplegar.
        // Ningún código la referencia: se elimina.
        Schema::dropIfExists('admins');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No se recrea: la migración original (2025_05_21_114858_create_admins_table)
        // fue eliminada del repo junto al guard legacy.
    }
};

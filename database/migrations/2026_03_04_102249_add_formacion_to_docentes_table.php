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
        Schema::table('docentes', function (Blueprint $table) {
            // Añadimos el booleano. Por defecto será 'false' (no tiene formación)
            $table->boolean('formacion')->default(false)->after('apellido');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('docentes', function (Blueprint $table) {
            // Esto sirve para deshacer el cambio si fuera necesario
            $table->dropColumn('formacion');
        });
    }
};

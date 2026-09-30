<section class="max-w-4xl mx-auto">
    <header class="mb-8">
        <h2 class="text-2xl font-semibold text-gray-800">
            {{ __('Perfil de Usuario') }}
        </h2>

        <p class="mt-2 text-base text-gray-600">
            {{ __('Información detallada de tu cuenta.') }}
        </p>
    </header>

    <div class="bg-white shadow-sm rounded-lg overflow-hidden">
        <div class="p-6 space-y-6">
            <div class="border-b border-gray-200 pb-4">
                <h3 class="text-lg font-medium text-gray-700 mb-4">{{ __('Información Personal') }}</h3>
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <x-input-label for="email" :value="__('ID Centro')" />
                        <x-text-input 
                            id="email" 
                            name="email" 
                            type="email" 
                            class="mt-1 block w-full bg-gray-50 cursor-not-allowed" 
                            :value="old('id_centro', $user->id_centro)" 
                            readonly 
                            disabled
                        />
                    </div>

                    <div>
                        <x-input-label for="name" :value="__('Nombre ')" />
                        <x-text-input 
                            id="name" 
                            name="name" 
                            type="text" 
                            class="mt-1 block w-full bg-gray-50 cursor-not-allowed" 
                            :value="old('nombre', $user->nombre)" 
                            readonly 
                            disabled
                        />
                    </div>

                    
                </div>
            </div>  
        </div>
    </div>
</section>
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MarkReimbursementAsPaidRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true; // L'autorisation sera gérée dans le contrôleur
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'from_user_id' => 'required|exists:users,id',
            'to_user_id' => 'required|exists:users,id',
            'amount' => 'required|numeric|min:0',
            'payment_proof' => 'nullable|string',
            'notes' => 'nullable|string',
        ];
    }

    /**
     * Get custom messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'from_user_id.required' => 'L\'utilisateur payeur est requis',
            'from_user_id.exists' => 'L\'utilisateur payeur n\'existe pas',
            'to_user_id.required' => 'L\'utilisateur bénéficiaire est requis',
            'to_user_id.exists' => 'L\'utilisateur bénéficiaire n\'existe pas',
            'amount.required' => 'Le montant est requis',
            'amount.numeric' => 'Le montant doit être un nombre',
            'amount.min' => 'Le montant doit être positif',
        ];
    }
}

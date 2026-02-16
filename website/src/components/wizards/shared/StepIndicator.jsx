import { CheckIcon } from '@heroicons/react/24/solid';

export default function StepIndicator({ currentStep, totalSteps, steps = [] }) {
    return (
        <div className="step-indicator">
            {Array.from({ length: totalSteps }, (_, i) => i + 1).map((step, index) => (
                <div key={step} className="step flex-1">
                    <div className="flex items-center">
                        {/* Step Circle */}
                        <div className={`step-circle ${step < currentStep ? 'completed' :
                                step === currentStep ? 'active' : 'pending'
                            }`}>
                            {step < currentStep ? (
                                <CheckIcon className="w-6 h-6" />
                            ) : (
                                <span>{step}</span>
                            )}
                        </div>

                        {/* Step Line (except for last step) */}
                        {index < totalSteps - 1 && (
                            <div className={`step-line ${step < currentStep ? 'completed' : 'pending'
                                }`} />
                        )}
                    </div>

                    {/* Step Label */}
                    {steps[index] && (
                        <div className="mt-2 text-center">
                            <p className={`text-sm font-medium ${step === currentStep ? 'text-primary-600' :
                                    step < currentStep ? 'text-green-600' : 'text-gray-500'
                                }`}>
                                {steps[index]}
                            </p>
                        </div>
                    )}
                </div>
            ))}
        </div>
    );
}

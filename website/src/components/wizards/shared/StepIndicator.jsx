import React from 'react';
import { CheckIcon } from '@heroicons/react/24/solid';

export default function StepIndicator({ currentStep, totalSteps, steps = [] }) {
    return (
        <div className="step-indicator">
            {Array.from({ length: totalSteps }, (_, i) => i + 1).map((step, index) => (
                <React.Fragment key={step}>
                    <div className="flex flex-col items-center">
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

                        {/* Step Label */}
                        {steps[index] && (
                            <p className={`mt-2 text-sm font-medium whitespace-nowrap ${step === currentStep ? 'text-primary-600' :
                                step < currentStep ? 'text-green-600' : 'text-gray-500'
                                }`}>
                                {steps[index]}
                            </p>
                        )}
                    </div>

                    {/* Step Line (except for last step) */}
                    {index < totalSteps - 1 && (
                        <div className={`step-line ${step < currentStep ? 'completed' : 'pending'
                            }`} />
                    )}
                </React.Fragment>
            ))}
        </div>
    );
}

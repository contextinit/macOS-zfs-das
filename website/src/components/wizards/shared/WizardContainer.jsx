import { useState, useEffect } from 'react';
import Button from '../../common/Button';

export default function WizardContainer({
    children,
    currentStep,
    totalSteps,
    onNext,
    onPrevious,
    onFinish,
    canGoNext = true,
    canGoPrevious = true,
    isLastStep = false,
    commandsToCopy = '',
}) {
    const [copied, setCopied] = useState(false);

    // Reset copied state if user navigates away from last step
    useEffect(() => {
        if (!isLastStep) {
            setCopied(false);
        }
    }, [isLastStep]);

    const handleFinish = async () => {
        if (commandsToCopy) {
            try {
                await navigator.clipboard.writeText(commandsToCopy);
                setCopied(true);
            } catch {
                // Fallback for older browsers
                const textarea = document.createElement('textarea');
                textarea.value = commandsToCopy;
                textarea.style.position = 'fixed';
                textarea.style.opacity = '0';
                document.body.appendChild(textarea);
                textarea.select();
                document.execCommand('copy');
                document.body.removeChild(textarea);
                setCopied(true);
            }
        }
        if (onFinish) {
            onFinish();
        }
    };

    return (
        <div className="max-w-4xl mx-auto">
            <div className="bg-white rounded-xl shadow-soft p-8">
                {children}

                {/* Navigation Buttons */}
                <div className="flex justify-between items-center mt-8 pt-6 border-t">
                    <Button
                        variant="secondary"
                        onClick={onPrevious}
                        disabled={!canGoPrevious || currentStep === 1}
                        className={currentStep === 1 ? 'invisible' : ''}
                    >
                        Previous
                    </Button>

                    <div className="flex items-center gap-3">
                        {copied && (
                            <span className="text-green-600 text-sm font-medium animate-fade-in flex items-center gap-1">
                                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                </svg>
                                Commands Copied!
                            </span>
                        )}

                        {isLastStep ? (
                            <Button
                                variant="primary"
                                onClick={handleFinish}
                                disabled={copied}
                            >
                                {copied ? '✓ Copied' : 'Finish'}
                            </Button>
                        ) : (
                            <Button
                                variant="primary"
                                onClick={onNext}
                                disabled={!canGoNext}
                            >
                                Next
                            </Button>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}

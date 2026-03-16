import { useState, useEffect } from 'react';
import Button from '../../common/Button';
import { trackWizardStep, trackWizardComplete, trackCopyCommand } from '../../../utils/analytics';

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
    wizardName = 'unknown',
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
                trackCopyCommand(commandsToCopy);
            } catch {
                // Clipboard API unavailable — show a visible error rather than
                // silently failing or using the deprecated execCommand API.
                alert('Could not copy automatically. Please select the text and copy it manually (Cmd+C).');
            }
        }
        trackWizardComplete(wizardName);
        if (onFinish) {
            onFinish();
        }
    };

    const handleNext = () => {
        trackWizardStep(wizardName, currentStep + 1, totalSteps, 'next');
        if (onNext) onNext();
    };

    const handlePrevious = () => {
        trackWizardStep(wizardName, currentStep - 1, totalSteps, 'previous');
        if (onPrevious) onPrevious();
    };

    return (
        <div className="max-w-4xl mx-auto">
            <div className="bg-white rounded-xl shadow-soft p-8">
                {children}

                {/* Navigation Buttons */}
                <div className="flex justify-between items-center mt-8 pt-6 border-t">
                    <Button
                        variant="secondary"
                        onClick={handlePrevious}
                        disabled={!canGoPrevious || currentStep === 1}
                        className={currentStep === 1 ? 'invisible' : ''}
                    >
                        Previous
                    </Button>

                    <div className="flex items-center gap-3">
                        <div aria-live="polite" aria-atomic="true">
                            {copied && (
                                <span className="text-green-600 text-sm font-medium animate-fade-in flex items-center gap-1">
                                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                    </svg>
                                    Commands Copied!
                                </span>
                            )}
                        </div>

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
                                onClick={handleNext}
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

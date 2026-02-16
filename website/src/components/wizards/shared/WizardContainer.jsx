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
}) {
    return (
        <div className="max-w-4xl mx-auto">
            <div className="bg-white rounded-xl shadow-soft p-8">
                {children}

                {/* Navigation Buttons */}
                <div className="flex justify-between mt-8 pt-6 border-t">
                    <Button
                        variant="secondary"
                        onClick={onPrevious}
                        disabled={!canGoPrevious || currentStep === 1}
                        className={currentStep === 1 ? 'invisible' : ''}
                    >
                        Previous
                    </Button>

                    {isLastStep ? (
                        <Button
                            variant="primary"
                            onClick={onFinish}
                        >
                            Finish
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
    );
}

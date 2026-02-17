import { useState } from 'react';
import { Link } from 'react-router-dom';
import StepIndicator from './shared/StepIndicator';
import WizardContainer from './shared/WizardContainer';
import CommandBlock from './shared/CommandBlock';

export default function SwiftBarWizard() {
    const [currentStep, setCurrentStep] = useState(1);
    const [config, setConfig] = useState({
        hasHomebrew: false,
        hasSwiftBar: false,
        monitoringLevel: 'advanced',
        poolName: 'media_pool',
    });

    const steps = ['Prerequisites', 'Install Homebrew', 'Install SwiftBar', 'Configure Plugin', 'Complete'];
    const totalSteps = 5;

    const handleNext = () => setCurrentStep(Math.min(currentStep + 1, totalSteps));
    const handlePrev = () => setCurrentStep(Math.max(currentStep - 1, 1));

    return (
        <div className="py-12">
            <div className="max-w-5xl mx-auto px-4">
                <div className="text-center mb-8">
                    <h1 className="text-3xl font-bold text-gray-900 mb-2">SwiftBar Setup Wizard</h1>
                    <p className="text-gray-600">Install real-time ZFS monitoring in your menu bar</p>

                    <div className="mt-6 mx-auto max-w-2xl p-3 bg-amber-50 border-l-4 border-amber-500 rounded-r-lg">
                        <div className="flex items-center">
                            <svg className="h-5 w-5 text-amber-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                            </svg>
                            <p className="ml-3 text-sm text-amber-800">
                                <strong>Important:</strong> Ensure{' '}
                                <Link to="/getting-started#prerequisites" className="text-amber-900 hover:text-amber-700 font-semibold underline">
                                    prerequisites
                                </Link>{' '}
                                are met before proceeding.
                            </p>
                        </div>
                    </div>
                </div>

                <StepIndicator currentStep={currentStep} totalSteps={totalSteps} steps={steps} />

                <WizardContainer
                    currentStep={currentStep}
                    totalSteps={totalSteps}
                    onNext={handleNext}
                    onPrevious={handlePrev}
                    isLastStep={currentStep === totalSteps}
                    commandsToCopy={`# SwiftBar ZFS Monitoring Setup\n\n# Install SwiftBar\nbrew install swiftbar\n\n# Copy plugin to SwiftBar directory\ncp swiftbar/zfs-${config.monitoringLevel}.30s.sh ~/Library/Application\\ Support/SwiftBar/\n\n# Make executable\nchmod +x ~/Library/Application\\ Support/SwiftBar/zfs-${config.monitoringLevel}.30s.sh\n\n# Refresh SwiftBar (Cmd+R in SwiftBar menu)`}
                >
                    {currentStep === 1 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold">Check Prerequisites</h2>

                            <div className="space-y-4">
                                <label className="flex items-center p-4 border-2 border-gray-200 rounded-lg hover:border-primary-500 cursor-pointer">
                                    <input
                                        type="checkbox"
                                        checked={config.hasHomebrew}
                                        onChange={(e) => setConfig({ ...config, hasHomebrew: e.target.checked })}
                                        className="w-5 h-5"
                                    />
                                    <span className="ml-3 text-gray-700">I have Homebrew installed</span>
                                </label>

                                {!config.hasHomebrew && (
                                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                                        <p className="text-sm text-blue-800">
                                            Homebrew is required. We'll install it in the next step.
                                        </p>
                                    </div>
                                )}
                            </div>
                        </div>
                    )}

                    {currentStep === 2 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold">Install Homebrew</h2>

                            {config.hasHomebrew ? (
                                <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                                    <p className="text-green-800">✓ You already have Homebrew! Skip to next step.</p>
                                </div>
                            ) : (
                                <>
                                    <p>Run this command in Terminal:</p>
                                    <CommandBlock command='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' />
                                    <p className="text-sm text-gray-600">After installation, verify with: brew --version</p>
                                </>
                            )}
                        </div>
                    )}

                    {currentStep === 3 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold">Install SwiftBar</h2>
                            <CommandBlock command="brew install swiftbar" />
                            <p className="text-sm text-gray-600">
                                After installation, launch SwiftBar from Applications folder
                            </p>
                        </div>
                    )}

                    {currentStep === 4 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold">Configure Monitoring Level</h2>

                            <div className="space-y-4">
                                <label className="flex items-center p-4 border-2 border-gray-200 rounded-lg hover:border-primary-500 cursor-pointer">
                                    <input
                                        type="radio"
                                        name="level"
                                        value="basic"
                                        checked={config.monitoringLevel === 'basic'}
                                        onChange={(e) => setConfig({ ...config, monitoringLevel: e.target.value })}
                                        className="w-4 h-4"
                                    />
                                    <div className="ml-3">
                                        <div className="font-medium">Basic Monitoring</div>
                                        <div className="text-sm text-gray-600">Pool health, capacity, errors</div>
                                    </div>
                                </label>

                                <label className="flex items-center p-4 border-2 border-primary-500 bg-primary-50 rounded-lg cursor-pointer">
                                    <input
                                        type="radio"
                                        name="level"
                                        value="advanced"
                                        checked={config.monitoringLevel === 'advanced'}
                                        onChange={(e) => setConfig({ ...config, monitoringLevel: e.target.value })}
                                        className="w-4 h-4"
                                    />
                                    <div className="ml-3">
                                        <div className="font-medium">Advanced Monitoring (Recommended)</div>
                                        <div className="text-sm text-gray-600">All basic features + trends, ARC stats, per-dataset details</div>
                                    </div>
                                </label>
                            </div>

                            <div className="mt-6">
                                <CommandBlock command={`# Copy plugin to SwiftBar directory
cp swiftbar/zfs-${config.monitoringLevel}.30s.sh ~/Library/Application\\ Support/SwiftBar/

# Make executable
chmod +x ~/Library/Application\\ Support/SwiftBar/zfs-${config.monitoringLevel}.30s.sh

# Refresh SwiftBar (Cmd+R in SwiftBar menu)`} />
                            </div>
                        </div>
                    )}

                    {currentStep === 5 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold text-green-600">✓ Setup Complete!</h2>

                            <div className="bg-green-50 border border-green-200 rounded-lg p-6">
                                <h3 className="font-semibold text-green-900 mb-3">Your ZFS monitoring is now active!</h3>
                                <ul className="space-y-2 text-green-800">
                                    <li>→ Check your menu bar for the ZFS icon</li>
                                    <li>→ Click to see detailed pool information</li>
                                    <li>→ Updates automatically every 30 seconds</li>
                                    <li>→ Color-coded alerts for issues</li>
                                </ul>
                            </div>

                            <div className="mt-6 p-6 border-2 border-dashed border-gray-300 rounded-lg text-center">
                                <p className="text-gray-600 mb-2">Next: Set up automated maintenance</p>
                                <a href="/wizards" className="text-primary-600 hover:underline font-medium">
                                    Explore More Wizards →
                                </a>
                            </div>
                        </div>
                    )}
                </WizardContainer>
            </div>
        </div>
    );
}

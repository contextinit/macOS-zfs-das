import { useState } from 'react';
import { Link } from 'react-router-dom';
import StepIndicator from './shared/StepIndicator';
import WizardContainer from './shared/WizardContainer';
import CommandBlock from './shared/CommandBlock';
import { validatePoolName, validateDatasetName, validateQuota, validateShareName } from '../../utils/wizardValidation';

export default function TimeMachineWizard() {
    const [currentStep, setCurrentStep] = useState(1);
    const [config, setConfig] = useState({
        poolName: 'media_pool',
        tmDataset: 'timemachine',
        tmSize: '500G',
        shareName: 'TimeMachine',
        allowedMacs: '',
    });

    const steps = ['Introduction', 'Create Dataset', 'Configure Sharing', 'Client Setup', 'Complete'];
    const totalSteps = 5;
    const [errors, setErrors] = useState({});

    const validateStep = (step) => {
        const newErrors = {};
        if (step === 2) {
            const poolErr = validatePoolName(config.poolName);
            if (poolErr) newErrors.poolName = poolErr;
            const datasetErr = validateDatasetName(config.tmDataset);
            if (datasetErr) newErrors.tmDataset = datasetErr;
            const quotaErr = validateQuota(config.tmSize);
            if (quotaErr) newErrors.tmSize = quotaErr;
        }
        if (step === 3) {
            const shareErr = validateShareName(config.shareName);
            if (shareErr) newErrors.shareName = shareErr;
        }
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleNext = () => {
        if (!validateStep(currentStep)) return;
        setCurrentStep(Math.min(currentStep + 1, totalSteps));
    };
    const handlePrev = () => setCurrentStep(Math.max(currentStep - 1, 1));

    const generateCommands = () => {
        return `# Time Machine Dataset Creation and Configuration

# 1. Create Time Machine dataset
sudo zfs create ${config.poolName}/${config.tmDataset}
sudo zfs set quota=${config.tmSize} ${config.poolName}/${config.tmDataset}
sudo zfs set atime=off ${config.poolName}/${config.tmDataset}

# 2. Set permissions
sudo chmod 770 /Volumes/${config.poolName}/${config.tmDataset}

# 3. Configure SMB sharing
# Edit /etc/smb.conf and add:
# [${config.shareName}]
#   path = /Volumes/${config.poolName}/${config.tmDataset}
#   valid users = ${config.allowedMacs || 'YOUR_USERNAME'}
#   read only = no
#   vfs objects = fruit streams_xattr
#   fruit:time machine = yes

# 4. Restart SMB service
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.smbd.plist
sudo launchctl load /System/Library/LaunchDaemons/com.apple.smbd.plist

echo "✓ Time Machine share configured!"
echo "Connect from client: smb://$(hostname)/${config.shareName}"`;
    };

    return (
        <div className="py-12">
            <div className="max-w-5xl mx-auto px-4">
                <div className="text-center mb-8">
                    <h1 className="text-3xl font-bold text-gray-900 mb-2">Time Machine Setup Wizard</h1>
                    <p className="text-gray-600">Configure network Time Machine backups on ZFS</p>

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
                    wizardName="time_machine"
                    commandsToCopy={generateCommands()}
                >
                    {currentStep === 1 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold">Network Time Machine Backups</h2>
                            <p>
                                This wizard will help you set up a dedicated ZFS dataset for Time Machine backups,
                                configure SMB sharing, and connect your Macs.
                            </p>
                            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                                <h3 className="font-semibold text-blue-900 mb-2">Benefits:</h3>
                                <ul className="space-y-1 text-blue-800">
                                    <li>→ Centralized backups for multiple Macs</li>
                                    <li>→ ZFS snapshots for backup versioning</li>
                                    <li>→ Quota management to prevent overfilling</li>
                                    <li>→ Network-accessible from anywhere</li>
                                </ul>
                            </div>
                        </div>
                    )}

                    {currentStep === 2 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold">Create Time Machine Dataset</h2>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Pool Name
                                </label>
                                <input
                                    type="text"
                                    value={config.poolName}
                                    onChange={(e) => { setConfig({ ...config, poolName: e.target.value }); setErrors({ ...errors, poolName: null }); }}
                                    className={`w-full px-4 py-3 border rounded-lg ${errors.poolName ? 'border-red-500' : 'border-gray-300'}`}
                                />
                                {errors.poolName && <p className="mt-1 text-sm text-red-600">{errors.poolName}</p>}
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Dataset Name
                                </label>
                                <input
                                    type="text"
                                    value={config.tmDataset}
                                    onChange={(e) => { setConfig({ ...config, tmDataset: e.target.value }); setErrors({ ...errors, tmDataset: null }); }}
                                    className={`w-full px-4 py-3 border rounded-lg ${errors.tmDataset ? 'border-red-500' : 'border-gray-300'}`}
                                    placeholder="timemachine"
                                />
                                {errors.tmDataset && <p className="mt-1 text-sm text-red-600">{errors.tmDataset}</p>}
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Size Quota (per Mac, recommended: 2-3x your Mac's storage)
                                </label>
                                <input
                                    type="text"
                                    value={config.tmSize}
                                    onChange={(e) => { setConfig({ ...config, tmSize: e.target.value }); setErrors({ ...errors, tmSize: null }); }}
                                    className={`w-full px-4 py-3 border rounded-lg ${errors.tmSize ? 'border-red-500' : 'border-gray-300'}`}
                                    placeholder="500G"
                                />
                                {errors.tmSize && <p className="mt-1 text-sm text-red-600">{errors.tmSize}</p>}
                                <p className="mt-2 text-sm text-gray-500">Examples: 500G, 1T, 2T</p>
                            </div>
                        </div>
                    )}

                    {currentStep === 3 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold">Configure SMB Sharing</h2>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Share Name
                                </label>
                                <input
                                    type="text"
                                    value={config.shareName}
                                    onChange={(e) => { setConfig({ ...config, shareName: e.target.value }); setErrors({ ...errors, shareName: null }); }}
                                    className={`w-full px-4 py-3 border rounded-lg ${errors.shareName ? 'border-red-500' : 'border-gray-300'}`}
                                />
                                {errors.shareName && <p className="mt-1 text-sm text-red-600">{errors.shareName}</p>}
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Allowed Users (comma-separated, leave empty for current user)
                                </label>
                                <input
                                    type="text"
                                    value={config.allowedMacs}
                                    onChange={(e) => setConfig({ ...config, allowedMacs: e.target.value })}
                                    className="w-full px-4 py-3 border border-gray-300 rounded-lg"
                                    placeholder="user1, user2"
                                />
                            </div>

                            <CommandBlock command={generateCommands()} />
                        </div>
                    )}

                    {currentStep === 4 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold">Connect Your Macs</h2>

                            <div className="bg-gray-50 rounded-lg p-6 space-y-4">
                                <div>
                                    <h3 className="font-semibold mb-2">Step 1: Connect to Share</h3>
                                    <p className="text-sm text-gray-700">In Finder, press Cmd+K and enter:</p>
                                    <code className="block mt-2 px-3 py-2 bg-gray-900 text-gray-100 rounded">
                                        smb://YOUR_SERVER_IP/{config.shareName}
                                    </code>
                                </div>

                                <div>
                                    <h3 className="font-semibold mb-2">Step 2: Open Time Machine Preferences</h3>
                                    <p className="text-sm text-gray-700">
                                        System Settings → General → Time Machine → Select Disk
                                    </p>
                                </div>

                                <div>
                                    <h3 className="font-semibold mb-2">Step 3: Select Network Share</h3>
                                    <p className="text-sm text-gray-700">
                                        Choose your {config.shareName} share from the list
                                    </p>
                                </div>

                                <div>
                                    <h3 className="font-semibold mb-2">Step 4: Start Backup</h3>
                                    <p className="text-sm text-gray-700">
                                        Click "Back Up Now" to start your first backup
                                    </p>
                                </div>
                            </div>
                        </div>
                    )}

                    {currentStep === 5 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold text-green-600">✓ Time Machine Configured!</h2>

                            <div className="bg-green-50 border border-green-200 rounded-lg p-6">
                                <h3 className="font-semibold text-green-900 mb-3">Your Time Machine setup is complete!</h3>
                                <ul className="space-y-2 text-green-800">
                                    <li>→ Dataset: {config.poolName}/{config.tmDataset}</li>
                                    <li>→ Quota: {config.tmSize}</li>
                                    <li>→ Share: {config.shareName}</li>
                                    <li>→ Backups run automatically every hour</li>
                                </ul>
                            </div>

                            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                                <h3 className="font-semibold text-blue-900 mb-2">Pro Tips:</h3>
                                <ul className="space-y-1 text-sm text-blue-800">
                                    <li>→ Create ZFS snapshots of the dataset for extra protection</li>
                                    <li>→ Monitor backup size: zfs get used {config.poolName}/{config.tmDataset}</li>
                                    <li>→ Adjust quota if needed: sudo zfs set quota=1T {config.poolName}/{config.tmDataset}</li>
                                </ul>
                            </div>
                        </div>
                    )}
                </WizardContainer>
            </div>
        </div>
    );
}

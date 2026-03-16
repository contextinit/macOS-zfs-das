import { useState } from 'react';
import { Link } from 'react-router-dom';
import StepIndicator from './shared/StepIndicator';
import WizardContainer from './shared/WizardContainer';
import CommandBlock from './shared/CommandBlock';
import { trackWizardConfig } from '../../utils/analytics';
import { validatePoolName, validateDrives } from '../../utils/wizardValidation';

export default function PoolCreationWizard() {
    const [currentStep, setCurrentStep] = useState(1);
    const [config, setConfig] = useState({
        poolName: 'media_pool',
        raidType: 'raidz2',
        drives: [],
        compression: 'lz4',
        encryption: true,
        keyLocation: '/etc/zfs/keys',
    });
    const [errors, setErrors] = useState({});

    const steps = ['Introduction', 'RAID & Drives', 'Configuration', 'Review', 'Commands'];
    const totalSteps = 5;

    const validateStep = (step) => {
        const newErrors = {};
        if (step === 2) {
            const drivesError = validateDrives(config.drives.join(' '));
            if (drivesError) newErrors.drives = drivesError;
        }
        if (step === 3) {
            const poolNameError = validatePoolName(config.poolName);
            if (poolNameError) newErrors.poolName = poolNameError;
        }
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleNext = () => {
        if (!validateStep(currentStep)) return;
        if (currentStep < totalSteps) {
            setCurrentStep(currentStep + 1);
        }
    };

    const handlePrev = () => {
        if (currentStep > 1) {
            setCurrentStep(currentStep - 1);
        }
    };

    const generateCommands = () => {
        const drives = config.drives.join(' ');
        const encryptionCmd = config.encryption
            ? `-O encryption=aes-256-gcm -O keyformat=raw -O keylocation=file://${config.keyLocation}/${config.poolName}.key`
            : '';

        return `# Generated ZFS Pool Creation Script
# Pool Name: ${config.poolName}
# RAID Type: ${config.raidType}

# 1. Create encryption key (if enabled)
${config.encryption ? `sudo mkdir -p ${config.keyLocation}
sudo dd if=/dev/random of=${config.keyLocation}/${config.poolName}.key bs=32 count=1
sudo chmod 600 ${config.keyLocation}/${config.poolName}.key` : '# Encryption disabled'}

# 2. Create pool
sudo zpool create \\
  -o ashift=12 \\
  -O compression=${config.compression} \\
  -O atime=off \\
  ${encryptionCmd} \\
  ${config.poolName} ${config.raidType} ${drives}

# 3. Verify pool creation
sudo zpool status ${config.poolName}
sudo zfs list ${config.poolName}

echo "✓ Pool created successfully!"`;
    };

    return (
        <div className="py-12">
            <div className="max-w-5xl mx-auto px-4">
                <div className="text-center mb-8">
                    <h1 className="text-3xl font-bold text-gray-900 mb-2">Pool Creation Wizard</h1>
                    <p className="text-gray-600">Create your ZFS pool in 5 easy steps</p>

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
                    commandsToCopy={generateCommands()}
                    wizardName="pool_creation"
                >
                    {currentStep === 1 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold text-gray-900">Welcome to Pool Creation</h2>
                            <p className="text-gray-600">
                                This wizard will guide you through creating a ZFS pool with your preferred configuration.
                                We'll help you choose the right RAID level, configure encryption, and generate the exact
                                commands you need.
                            </p>
                            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                                <h3 className="font-semibold text-blue-900 mb-2">What You'll Configure:</h3>
                                <ul className="space-y-2 text-blue-800">
                                    <li>→ Pool name and RAID level (RAID-Z, RAID-Z2, mirror)</li>
                                    <li>→ Drive selection and configuration</li>
                                    <li>→ Encryption and compression settings</li>
                                    <li>→ Advanced options for performance</li>
                                </ul>
                            </div>
                        </div>
                    )}

                    {currentStep === 2 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold text-gray-900">RAID Type & Drive Selection</h2>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Select RAID Type
                                </label>
                                <select
                                    value={config.raidType}
                                    onChange={(e) => {
                                        setConfig({ ...config, raidType: e.target.value });
                                        trackWizardConfig('pool_creation', 'raid_type', e.target.value);
                                    }}
                                    className="w-full px-4 py-3 border border-gray-300 rounded-lg"
                                >
                                    <option value="mirror">Mirror (2 drives, 50% capacity, survives 1 failure)</option>
                                    <option value="raidz">RAID-Z (3+ drives, survives 1 failure)</option>
                                    <option value="raidz2">RAID-Z2 (4+ drives, survives 2 failures) - Recommended</option>
                                    <option value="raidz3">RAID-Z3 (5+ drives, survives 3 failures)</option>
                                </select>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Drive Identifiers (space-separated)
                                </label>
                                <input
                                    type="text"
                                    value={config.drives.join(' ')}
                                    onChange={(e) => {
                                        setConfig({ ...config, drives: e.target.value.split(/\s+/).filter(Boolean) });
                                        setErrors({ ...errors, drives: null });
                                    }}
                                    placeholder="disk2 disk3 disk4 disk5"
                                    className={`w-full px-4 py-3 border rounded-lg ${errors.drives ? 'border-red-500' : 'border-gray-300'}`}
                                />
                                {errors.drives && <p className="mt-1 text-sm text-red-600">{errors.drives}</p>}
                                <p className="mt-2 text-sm text-gray-500">
                                    Use <code>diskutil list</code> to find your drive identifiers
                                </p>
                            </div>
                        </div>
                    )}

                    {currentStep === 3 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold text-gray-900">Configuration Options</h2>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Pool Name
                                </label>
                                <input
                                    type="text"
                                    value={config.poolName}
                                    onChange={(e) => {
                                        setConfig({ ...config, poolName: e.target.value });
                                        setErrors({ ...errors, poolName: null });
                                    }}
                                    className={`w-full px-4 py-3 border rounded-lg ${errors.poolName ? 'border-red-500' : 'border-gray-300'}`}
                                />
                                {errors.poolName && <p className="mt-1 text-sm text-red-600">{errors.poolName}</p>}
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Compression Algorithm
                                </label>
                                <select
                                    value={config.compression}
                                    onChange={(e) => {
                                        setConfig({ ...config, compression: e.target.value });
                                        trackWizardConfig('pool_creation', 'compression', e.target.value);
                                    }}
                                    className="w-full px-4 py-3 border border-gray-300 rounded-lg"
                                >
                                    <option value="lz4">LZ4 (Recommended - Fast & Efficient)</option>
                                    <option value="gzip">gzip (Higher compression, slower)</option>
                                    <option value="zstd">zstd (Balanced)</option>
                                    <option value="off">Off (No compression)</option>
                                </select>
                            </div>

                            <div>
                                <label className="flex items-center">
                                    <input
                                        type="checkbox"
                                        checked={config.encryption}
                                        onChange={(e) => {
                                            setConfig({ ...config, encryption: e.target.checked });
                                            trackWizardConfig('pool_creation', 'encryption', e.target.checked);
                                        }}
                                        className="w-4 h-4 text-primary-600 border-gray-300 rounded"
                                    />
                                    <span className="ml-2 text-sm text-gray-700">
                                        Enable AES-256-GCM encryption
                                    </span>
                                </label>
                            </div>
                        </div>
                    )}

                    {currentStep === 4 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold text-gray-900">Review Your Configuration</h2>

                            <div className="bg-gray-50 rounded-lg p-6 space-y-3">
                                <div className="flex justify-between">
                                    <span className="font-medium">Pool Name:</span>
                                    <span>{config.poolName}</span>
                                </div>
                                <div className="flex justify-between">
                                    <span className="font-medium">RAID Type:</span>
                                    <span>{config.raidType.toUpperCase()}</span>
                                </div>
                                <div className="flex justify-between">
                                    <span className="font-medium">Drives:</span>
                                    <span>{config.drives.join(', ')}</span>
                                </div>
                                <div className="flex justify-between">
                                    <span className="font-medium">Compression:</span>
                                    <span>{config.compression}</span>
                                </div>
                                <div className="flex justify-between">
                                    <span className="font-medium">Encryption:</span>
                                    <span>{config.encryption ? 'Enabled (AES-256-GCM)' : 'Disabled'}</span>
                                </div>
                            </div>

                            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                                <p className="text-sm text-yellow-800">
                                    ⚠️ Please review carefully. Creating a pool will format the selected drives and erase all data.
                                </p>
                            </div>
                        </div>
                    )}

                    {currentStep === 5 && (
                        <div className="space-y-6">
                            <h2 className="text-2xl font-bold text-gray-900">Your Custom Commands</h2>
                            <p className="text-gray-600">
                                Copy and run these commands to create your pool:
                            </p>

                            <CommandBlock command={generateCommands()} />

                            <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                                <h3 className="font-semibold text-green-900 mb-2">✓ Next Steps:</h3>
                                <ol className="list-decimal list-inside space-y-1 text-green-800">
                                    <li>Copy the commands above</li>
                                    <li>Open Terminal</li>
                                    <li>Paste and execute the commands</li>
                                    <li>Verify pool creation with zpool status</li>
                                </ol>
                            </div>
                        </div>
                    )}
                </WizardContainer>
            </div>
        </div>
    );
}

import { Routes, Route, Link } from 'react-router-dom';
import PoolCreationWizard from '../components/wizards/PoolCreationWizard';
import SwiftBarWizard from '../components/wizards/SwiftBarWizard';
import TimeMachineWizard from '../components/wizards/TimeMachineWizard';

export default function Wizards() {
    return (
        <div className="bg-gray-50 min-h-screen">
            <Routes>
                <Route index element={<WizardsHome />} />
                <Route path="pool-creation" element={<PoolCreationWizard />} />
                <Route path="swiftbar" element={<SwiftBarWizard />} />
                <Route path="timemachine" element={<TimeMachineWizard />} />
            </Routes>
        </div>
    );
}

function WizardsHome() {
    const wizards = [
        {
            title: 'Pool Creation Wizard',
            description: 'Create and configure your ZFS pool with RAID-Z, encryption, and compression',
            path: '/wizards/pool-creation',
            icon: '🏊',
            steps: 5,
            time: '10 min',
        },
        {
            title: 'SwiftBar Setup Wizard',
            description: 'Install and configure SwiftBar for real-time ZFS monitoring in your menu bar',
            path: '/wizards/swiftbar',
            icon: '📊',
            steps: 5,
            time: '5 min',
        },
        {
            title: 'Time Machine Wizard',
            description: 'Set up network Time Machine backups with automatic sharing configuration',
            path: '/wizards/timemachine',
            icon: '⏰',
            steps: 5,
            time: '8 min',
        },
    ];

    return (
        <div className="py-20">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="text-center mb-12">
                    <h1 className="text-4xl font-bold text-gray-900 mb-4">
                        Interactive Setup Wizards
                    </h1>
                    <p className="text-xl text-gray-600 max-w-2xl mx-auto">
                        Step-by-step guides that generate custom scripts for your exact setup
                    </p>

                    <div className="max-w-3xl mx-auto mt-8 p-4 bg-amber-50 border-l-4 border-amber-500 rounded-r-lg shadow-sm">
                        <div className="flex items-start">
                            <div className="flex-shrink-0">
                                <svg className="h-6 w-6 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                                </svg>
                            </div>
                            <div className="ml-3 flex-1">
                                <p className="text-sm font-medium text-amber-800">
                                    <strong>Important:</strong> Before using these wizards, please ensure you have completed the{' '}
                                    <Link to="/getting-started#prerequisites" className="text-amber-900 hover:text-amber-700 font-semibold underline">
                                        prerequisites and installation steps
                                    </Link>.
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="grid md:grid-cols-3 gap-8">
                    {wizards.map((wizard) => (
                        <Link
                            key={wizard.path}
                            to={wizard.path}
                            className="bg-white rounded-xl shadow-soft p-8 hover:shadow-xl hover:scale-105 transition-all"
                        >
                            <div className="text-5xl mb-4">{wizard.icon}</div>
                            <h2 className="text-2xl font-bold text-gray-900 mb-3">{wizard.title}</h2>
                            <p className="text-gray-600 mb-6">{wizard.description}</p>

                            <div className="flex items-center justify-between text-sm text-gray-500 pt-4 border-t">
                                <span>{wizard.steps} steps</span>
                                <span>~{wizard.time}</span>
                            </div>
                        </Link>
                    ))}
                </div>
            </div>
        </div>
    );
}

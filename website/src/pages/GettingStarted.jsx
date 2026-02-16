import { Link } from 'react-router-dom';

export default function GettingStarted() {
    return (
        <div className="bg-gray-50 py-20">
            <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
                <h1 className="text-4xl font-bold text-gray-900 mb-6">Getting Started</h1>

                <div className="prose prose-lg max-w-none">
                    <p className="text-xl text-gray-600 mb-8">
                        Get up and running with macOS ZFS DAS in less than 30 minutes
                    </p>

                    {/* Prerequisites */}
                    <section className="bg-white rounded-xl p-8 mb-8 shadow-soft" id="prerequisites">
                        <h2 className="text-2xl font-bold mb-4">Prerequisites</h2>
                        <ul className="space-y-2">
                            <li>macOS 10.13 (High Sierra) or later</li>
                            <li>OpenZFS on macOS installed</li>
                            <li>Direct Attached Storage (DAS) connected</li>
                            <li>Admin/root access</li>
                        </ul>

                        <div className="mt-6">
                            <h3 className="font-semibold mb-2">Check Your System:</h3>
                            <div className="command-block">
                                <pre><code>./scripts/check-prerequisites.sh</code></pre>
                            </div>
                        </div>
                    </section>

                    {/* Installation */}
                    <section className="bg-white rounded-xl p-8 mb-8 shadow-soft" id="install">
                        <h2 className="text-2xl font-bold mb-4">1. Install OpenZFS</h2>
                        <p className="mb-4">Download and install OpenZFS from the official source:</p>
                        <div className="command-block mb-4">
                            <pre><code>brew install openzfs</code></pre>
                        </div>
                        <p className="text-sm text-gray-600">
                            Or download from: <a href="https://openzfsonosx.github.io/" className="text-primary-600 hover:underline">https://openzfsonosx.github.io/</a>
                        </p>
                    </section>

                    {/* Clone Repository */}
                    <section className="bg-white rounded-xl p-8 mb-8 shadow-soft">
                        <h2 className="text-2xl font-bold mb-4">2. Clone Repository</h2>
                        <div className="command-block">
                            <pre><code>{`git clone https://github.com/contextinit/macos-zfs-das.git
cd macos-zfs-das`}</code></pre>
                        </div>
                    </section>

                    {/* Quick Setup */}
                    <section className="bg-white rounded-xl p-8 mb-8 shadow-soft">
                        <h2 className="text-2xl font-bold mb-4">3. Create Your First Pool</h2>
                        <p className="mb-4">Use our interactive wizard for guided setup:</p>
                        <Link to="/wizards/pool-creation" className="btn btn-primary">
                            Launch Pool Creation Wizard →
                        </Link>

                        <p className="mt-6 text-sm text-gray-600">
                            Or follow the manual process in our <Link to="/docs/setup" className="text-primary-600 hover:underline">setup documentation</Link>
                        </p>
                    </section>

                    {/* Next Steps */}
                    <section className="bg-white rounded-xl p-8 shadow-soft">
                        <h2 className="text-2xl font-bold mb-4">Next Steps</h2>
                        <div className="grid md:grid-cols-2 gap-4">
                            <Link to="/wizards/swiftbar" className="block p-4 border-2 border-gray-200 rounded-lg hover:border-primary-500 transition">
                                <h3 className="font-semibold mb-2">Set Up Monitoring</h3>
                                <p className="text-sm text-gray-600">Install SwiftBar for menu bar monitoring</p>
                            </Link>
                            <Link to="/wizards/timemachine" className="block p-4 border-2 border-gray-200 rounded-lg hover:border-primary-500 transition">
                                <h3 className="font-semibold mb-2">Configure Time Machine</h3>
                                <p className="text-sm text-gray-600">Set up network Time Machine backups</p>
                            </Link>
                        </div>
                    </section>
                </div>
            </div>
        </div>
    );
}

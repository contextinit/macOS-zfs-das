import { Link } from 'react-router-dom';

export default function Download() {
    return (
        <div className="bg-gray-50 py-20">
            <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="text-center mb-12">
                    <h1 className="text-4xl font-bold text-gray-900 mb-4">
                        Download macOS ZFS DAS
                    </h1>
                    <p className="text-xl text-gray-600">
                        Get started with professional ZFS storage management for macOS
                    </p>
                </div>

                {/* Latest Release */}
                <div className="bg-white rounded-xl shadow-soft p-8 mb-8">
                    <div className="flex items-center justify-between mb-6">
                        <div>
                            <h2 className="text-2xl font-bold text-gray-900">Latest Release</h2>
                            <p className="text-gray-600">Version 1.0.0 - February 2026</p>
                        </div>
                        <span className="px-4 py-2 bg-green-100 text-green-700 rounded-full font-medium">
                            Stable
                        </span>
                    </div>

                    <div className="space-y-4">
                        <a
                            href="https://github.com/contextinit/macos-zfs-das/archive/refs/heads/main.zip"
                            className="btn btn-primary btn-lg w-full"
                        >
                            Download ZIP
                        </a>
                        <p className="text-center text-gray-500">or</p>
                        <div className="command-block">
                            <pre><code>{`git clone https://github.com/contextinit/macos-zfs-das.git`}</code></pre>
                        </div>
                    </div>
                </div>

                {/* System Requirements */}
                <div className="bg-white rounded-xl shadow-soft p-8 mb-8">
                    <h2 className="text-2xl font-bold text-gray-900 mb-4">System Requirements</h2>
                    <ul className="space-y-3">
                        <li className="flex items-center">
                            <span className="text-green-500 mr-3">✓</span>
                            <span>macOS 10.13 (High Sierra) or later</span>
                        </li>
                        <li className="flex items-center">
                            <span className="text-green-500 mr-3">✓</span>
                            <span>OpenZFS on macOS installed</span>
                        </li>
                        <li className="flex items-center">
                            <span className="text-green-500 mr-3">✓</span>
                            <span>Direct Attached Storage (DAS) device</span>
                        </li>
                        <li className="flex items-center">
                            <span className="text-green-500 mr-3">✓</span>
                            <span>Administrator privileges</span>
                        </li>
                    </ul>
                </div>

                {/* What's Included */}
                <div className="bg-white rounded-xl shadow-soft p-8">
                    <h2 className="text-2xl font-bold text-gray-900 mb-4">What's Included</h2>
                    <div className="grid md:grid-cols-2 gap-4">
                        {[
                            'Pool creation scripts',
                            'Automated maintenance',
                            'SwiftBar monitoring plugins',
                            'Encryption setup',
                            'Time Machine integration',
                            'Health check utilities',
                            'Snapshot management',
                            'Complete documentation',
                        ].map((item) => (
                            <div key={item} className="flex items-center">
                                <span className="text-primary-600 mr-2">→</span>
                                <span>{item}</span>
                            </div>
                        ))}
                    </div>
                </div>

                <div className="mt-8 text-center">
                    <p className="text-gray-600 mb-4">
                        Need help getting started?
                    </p>
                    <Link to="/getting-started" className="btn btn-secondary">
                        View Installation Guide
                    </Link>
                </div>
            </div>
        </div>
    );
}

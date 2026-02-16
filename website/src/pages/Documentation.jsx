import { Link } from 'react-router-dom';
import { CheckCircleIcon, ShieldCheckIcon, CurrencyDollarIcon, ClockIcon } from '@heroicons/react/24/outline';

export default function Documentation() {
    return (
        <div className="bg-gray-50 py-12">
            <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
                {/* Header */}
                <div className="text-center mb-12">
                    <h1 className="text-4xl font-bold text-gray-900 mb-4">Complete Setup Guide</h1>
                    <p className="text-xl text-gray-600">
                        Everything you need to know to get started with your own ZFS storage system
                    </p>
                </div>

                {/* Why This Solution */}
                <section className="bg-white rounded-xl p-8 mb-8 shadow-soft">
                    <h2 className="text-3xl font-bold text-gray-900 mb-6">Why Choose This Solution?</h2>

                    <p className="text-lg text-gray-700 mb-6">
                        If you're storing important files—photos, videos, documents, or work projects—you've probably worried
                        about losing them. Traditional external hard drives can fail. Cloud storage is expensive and requires
                        internet access. Commercial NAS devices cost thousands of dollars and lock you into proprietary systems.
                    </p>

                    <p className="text-lg text-gray-700 mb-6">
                        <strong className="text-primary-600">This solution gives you enterprise-level data protection at a fraction of the cost,</strong> using
                        equipment you may already have. Here's what makes it special:
                    </p>

                    <div className="grid md:grid-cols-2 gap-6 mb-6">
                        <div className="flex items-start space-x-3">
                            <ShieldCheckIcon className="h-6 w-6 text-green-600 flex-shrink-0 mt-1" />
                            <div>
                                <h3 className="font-semibold text-gray-900 mb-1">Your Data Actually Stays Safe</h3>
                                <p className="text-sm text-gray-600">
                                    ZFS checks every single file automatically. If a hard drive starts failing, it fixes the problem
                                    before you lose anything. No other consumer system does this.
                                </p>
                            </div>
                        </div>

                        <div className="flex items-start space-x-3">
                            <CurrencyDollarIcon className="h-6 w-6 text-green-600 flex-shrink-0 mt-1" />
                            <div>
                                <h3 className="font-semibold text-gray-900 mb-1">Save Thousands of Dollars</h3>
                                <p className="text-sm text-gray-600">
                                    Commercial NAS systems cost $2,000-$5,000+. This solution uses your Mac and affordable hard drives.
                                    A 4-drive setup with 16TB of protected storage costs under $500.
                                </p>
                            </div>
                        </div>

                        <div className="flex items-start space-x-3">
                            <CheckCircleIcon className="h-6 w-6 text-green-600 flex-shrink-0 mt-1" />
                            <div>
                                <h3 className="font-semibold text-gray-900 mb-1">No Vendor Lock-In</h3>
                                <p className="text-sm text-gray-600">
                                    Your data isn't trapped in a proprietary format. You're not paying monthly fees.
                                    You're not dependent on a company staying in business. You own and control everything.
                                </p>
                            </div>
                        </div>

                        <div className="flex items-start space-x-3">
                            <ClockIcon className="h-6 w-6 text-green-600 flex-shrink-0 mt-1" />
                            <div>
                                <h3 className="font-semibold text-gray-900 mb-1">Instant Time Travel</h3>
                                <p className="text-sm text-gray-600">
                                    Accidentally deleted files? Made changes you regret? ZFS snapshots let you go back in time
                                    instantly—without using any extra space.
                                </p>
                            </div>
                        </div>
                    </div>

                    <div className="bg-blue-50 border-l-4 border-blue-500 p-4 rounded-r-lg">
                        <p className="text-sm text-blue-800">
                            <strong>Real-world example:</strong> A photographer with 10TB of photos needs protection.
                            A Synology NAS costs $3,500+. Cloud storage costs $1,200/year forever. This solution?
                            A $400 one-time investment using drives you may already own.
                        </p>
                    </div>
                </section>

                {/* Getting Started Steps */}
                <section className="bg-white rounded-xl p-8 mb-8 shadow-soft">
                    <h2 className="text-3xl font-bold text-gray-900 mb-6">Step-by-Step Setup Guide</h2>
                    <p className="text-gray-600 mb-8">
                        Don't worry if you're not technical—we'll walk through everything together. Each step is explained
                        in plain English, and our interactive wizards do the hard work for you.
                    </p>

                    {/* Step 1 */}
                    <div className="mb-8 pb-8 border-b border-gray-200">
                        <div className="flex items-start space-x-4">
                            <div className="flex-shrink-0 w-10 h-10 bg-primary-600 text-white rounded-full flex items-center justify-center font-bold text-lg">
                                1
                            </div>
                            <div className="flex-1">
                                <h3 className="text-2xl font-bold text-gray-900 mb-3">Check What You Need</h3>
                                <p className="text-gray-700 mb-4">
                                    Before we start, let's make sure you have everything. You'll need:
                                </p>
                                <ul className="space-y-2 mb-4">
                                    <li className="flex items-start">
                                        <span className="text-primary-600 mr-2">✓</span>
                                        <span className="text-gray-700"><strong>A Mac computer</strong> running macOS 10.13 or newer (any Mac from 2017 or later works)</span>
                                    </li>
                                    <li className="flex items-start">
                                        <span className="text-primary-600 mr-2">✓</span>
                                        <span className="text-gray-700"><strong>External hard drives</strong> connected via USB, Thunderbolt, or a drive enclosure (at least 3-4 drives recommended)</span>
                                    </li>
                                    <li className="flex items-start">
                                        <span className="text-primary-600 mr-2">✓</span>
                                        <span className="text-gray-700"><strong>About 30 minutes</strong> for the initial setup</span>
                                    </li>
                                </ul>
                                <div className="bg-amber-50 border-l-4 border-amber-500 p-4 rounded-r-lg mb-4">
                                    <p className="text-sm text-amber-800">
                                        <strong>Important:</strong> The setup process will erase all data on the drives you choose.
                                        Make sure you've backed up anything important first!
                                    </p>
                                </div>
                                <Link to="/getting-started#prerequisites" className="text-primary-600 hover:text-primary-700 font-medium">
                                    See detailed requirements →
                                </Link>
                            </div>
                        </div>
                    </div>

                    {/* Step 2 */}
                    <div className="mb-8 pb-8 border-b border-gray-200">
                        <div className="flex items-start space-x-4">
                            <div className="flex-shrink-0 w-10 h-10 bg-primary-600 text-white rounded-full flex items-center justify-center font-bold text-lg">
                                2
                            </div>
                            <div className="flex-1">
                                <h3 className="text-2xl font-bold text-gray-900 mb-3">Install OpenZFS</h3>
                                <p className="text-gray-700 mb-4">
                                    OpenZFS is the free software that makes all this magic happen. Think of it like installing
                                    Microsoft Word, but for managing your storage drives.
                                </p>
                                <p className="text-gray-700 mb-4">
                                    We'll use Homebrew (a tool that makes installing Mac software easy) to set it up:
                                </p>
                                <div className="bg-gray-900 text-gray-100 rounded-lg p-4 mb-4">
                                    <code className="text-sm">brew install openzfs</code>
                                </div>

                                <div className="mb-4 border-2 border-gray-200 rounded-lg overflow-hidden">
                                    <img
                                        src="/images/terminal-openzfs-install.png"
                                        alt="Terminal window showing brew install openzfs command"
                                        className="w-full"
                                    />
                                    <p className="text-xs text-gray-500 bg-gray-50 px-3 py-2 border-t border-gray-200">
                                        Screenshot: Terminal window with the installation command
                                    </p>
                                </div>

                                <p className="text-sm text-gray-600 mb-4">
                                    Just paste that into Terminal (found in Applications → Utilities), press Enter, and wait
                                    a few minutes. It'll download and install everything automatically.
                                </p>
                                <Link to="/getting-started#install" className="text-primary-600 hover:text-primary-700 font-medium">
                                    Detailed installation instructions →
                                </Link>
                            </div>
                        </div>
                    </div>

                    {/* Step 3 */}
                    <div className="mb-8 pb-8 border-b border-gray-200">
                        <div className="flex items-start space-x-4">
                            <div className="flex-shrink-0 w-10 h-10 bg-primary-600 text-white rounded-full flex items-center justify-center font-bold text-lg">
                                3
                            </div>
                            <div className="flex-1">
                                <h3 className="text-2xl font-bold text-gray-900 mb-3">Download This Project</h3>
                                <p className="text-gray-700 mb-4">
                                    Next, we need to download the helpful scripts and tools that make managing ZFS super easy.
                                    Think of this as downloading a helpful instruction manual and toolkit.
                                </p>
                                <p className="text-gray-700 mb-4">
                                    You have two options:
                                </p>
                                <div className="space-y-4 mb-4">
                                    <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                                        <h4 className="font-semibold text-gray-900 mb-2">Option 1: Download as ZIP (Easier)</h4>
                                        <p className="text-sm text-gray-600 mb-3">
                                            Click the download button, unzip the file, and you're done. Perfect if you're not familiar with Git.
                                        </p>
                                        <Link to="/download" className="btn btn-primary btn-sm">
                                            Go to Download Page →
                                        </Link>
                                    </div>
                                    <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                                        <h4 className="font-semibold text-gray-900 mb-2">Option 2: Clone with Git (Recommended)</h4>
                                        <p className="text-sm text-gray-600 mb-3">
                                            This lets you easily get updates in the future. Open Terminal and paste:
                                        </p>
                                        <div className="bg-gray-900 text-gray-100 rounded-lg p-3">
                                            <code className="text-xs">git clone https://github.com/contextinit/macos-zfs-das.git</code>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Step 4 */}
                    <div className="mb-8 pb-8 border-b border-gray-200">
                        <div className="flex items-start space-x-4">
                            <div className="flex-shrink-0 w-10 h-10 bg-primary-600 text-white rounded-full flex items-center justify-center font-bold text-lg">
                                4
                            </div>
                            <div className="flex-1">
                                <h3 className="text-2xl font-bold text-gray-900 mb-3">Create Your ZFS Pool (The Fun Part!)</h3>
                                <p className="text-gray-700 mb-4">
                                    Now for the exciting part—setting up your protected storage pool! Don't worry, our interactive
                                    wizard makes this ridiculously easy.
                                </p>
                                <p className="text-gray-700 mb-4">
                                    The wizard will ask you simple questions like:
                                </p>
                                <ul className="space-y-2 mb-4 ml-6 list-disc text-gray-700">
                                    <li>What do you want to name your storage? (Like "family_photos" or "media_vault")</li>
                                    <li>How many drive failures should it survive? (We recommend 2 for safety)</li>
                                    <li>Do you want encryption? (Yes, especially for sensitive data!)</li>
                                    <li>Which compression should it use? (We recommend LZ4—it's fast and saves space)</li>
                                </ul>
                                <p className="text-gray-700 mb-4">
                                    At the end, it generates the exact commands you need. Just copy and paste them into Terminal!
                                </p>
                                <Link to="/wizards/pool-creation" className="btn btn-primary">
                                    Launch Pool Creation Wizard →
                                </Link>
                            </div>
                        </div>
                    </div>

                    {/* Step 5 */}
                    <div className="mb-8 pb-8 border-b border-gray-200">
                        <div className="flex items-start space-x-4">
                            <div className="flex-shrink-0 w-10 h-10 bg-primary-600 text-white rounded-full flex items-center justify-center font-bold text-lg">
                                5
                            </div>
                            <div className="flex-1">
                                <h3 className="text-2xl font-bold text-gray-900 mb-3">Set Up Monitoring (So You Sleep Easy)</h3>
                                <p className="text-gray-700 mb-4">
                                    Wouldn't it be nice to see your storage health right in your Mac's menu bar? That's what
                                    SwiftBar does—it shows you everything at a glance.
                                </p>
                                <p className="text-gray-700 mb-4">
                                    You'll see:
                                </p>
                                <ul className="space-y-2 mb-4 ml-6 list-disc text-gray-700">
                                    <li>Is everything healthy? ✓ Green means good!</li>
                                    <li>How much space am I using? See capacity at a glance</li>
                                    <li>Any errors? Get instant alerts if something needs attention</li>
                                </ul>
                                <p className="text-gray-700 mb-4">
                                    Our wizard handles the installation of SwiftBar and sets up the monitoring plugin for you.
                                </p>
                                <Link to="/wizards/swiftbar" className="btn btn-primary">
                                    Launch SwiftBar Setup Wizard →
                                </Link>
                            </div>
                        </div>
                    </div>

                    {/* Step 6 */}
                    <div className="mb-8">
                        <div className="flex items-start space-x-4">
                            <div className="flex-shrink-0 w-10 h-10 bg-primary-600 text-white rounded-full flex items-center justify-center font-bold text-lg">
                                6
                            </div>
                            <div className="flex-1">
                                <h3 className="text-2xl font-bold text-gray-900 mb-3">Set Up Time Machine (Optional but Awesome)</h3>
                                <p className="text-gray-700 mb-4">
                                    Want to back up all your Macs to this storage system? Our Time Machine wizard makes it super simple.
                                    You'll have network backups running in about 10 minutes.
                                </p>
                                <p className="text-gray-700 mb-4">
                                    This is perfect if you have multiple Macs in your home or office—everyone can back up to the
                                    same ZFS pool, and you can set space limits so one person doesn't hog all the storage.
                                </p>
                                <Link to="/wizards/timemachine" className="btn btn-primary">
                                    Launch Time Machine Wizard →
                                </Link>
                            </div>
                        </div>
                    </div>
                </section>

                {/* What Happens Next */}
                <section className="bg-gradient-to-br from-primary-50 to-accent-50 rounded-xl p-8 mb-8">
                    <h2 className="text-3xl font-bold text-gray-900 mb-6">What Happens Next?</h2>
                    <div className="space-y-4">
                        <div className="flex items-start space-x-3">
                            <CheckCircleIcon className="h-6 w-6 text-primary-600 flex-shrink-0 mt-1" />
                            <div>
                                <h3 className="font-semibold text-gray-900 mb-1">Automatic Protection</h3>
                                <p className="text-gray-700">
                                    Your files are constantly checked for corruption. If a drive starts failing, ZFS automatically
                                    fixes problems using the redundant copies. You don't have to do anything.
                                </p>
                            </div>
                        </div>
                        <div className="flex items-start space-x-3">
                            <CheckCircleIcon className="h-6 w-6 text-primary-600 flex-shrink-0 mt-1" />
                            <div>
                                <h3 className="font-semibold text-gray-900 mb-1">Monthly Maintenance</h3>
                                <p className="text-gray-700">
                                    Once a month, the system does a deep scan (called a "scrub") to verify every file. This happens
                                    automatically in the background—you'll get an email report when it's done.
                                </p>
                            </div>
                        </div>
                        <div className="flex items-start space-x-3">
                            <CheckCircleIcon className="h-6 w-6 text-primary-600 flex-shrink-0 mt-1" />
                            <div>
                                <h3 className="font-semibold text-gray-900 mb-1">Easy Snapshots</h3>
                                <p className="text-gray-700">
                                    Want to save the current state before making big changes? Create a snapshot in seconds.
                                    Messed something up? Roll back instantly. It's like time travel for your files.
                                </p>
                            </div>
                        </div>
                        <div className="flex items-start space-x-3">
                            <CheckCircleIcon className="h-6 w-6 text-primary-600 flex-shrink-0 mt-1" />
                            <div>
                                <h3 className="font-semibold text-gray-900 mb-1">Simple Expansion</h3>
                                <p className="text-gray-700">
                                    Running out of space? Just plug in more drives and expand your pool. No complicated migration
                                    or data transfers needed.
                                </p>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Need Help */}
                <section className="bg-white rounded-xl p-8 shadow-soft">
                    <h2 className="text-2xl font-bold text-gray-900 mb-4">Need Help?</h2>
                    <p className="text-gray-700 mb-6">
                        Stuck on something? That's totally normal! Here are your options:
                    </p>
                    <div className="grid md:grid-cols-2 gap-4">
                        <a
                            href="https://github.com/contextinit/macos-zfs-das"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="block p-4 border-2 border-gray-200 rounded-lg hover:border-primary-500 transition"
                        >
                            <h3 className="font-semibold mb-2">📖 GitHub Repository</h3>
                            <p className="text-sm text-gray-600">Check existing issues or create a new one</p>
                        </a>
                        <Link
                            to="/#contact"
                            className="block p-4 border-2 border-gray-200 rounded-lg hover:border-primary-500 transition"
                        >
                            <h3 className="font-semibold mb-2">✉️ Contact Us</h3>
                            <p className="text-sm text-gray-600">Get personalized help or book a consultation</p>
                        </Link>
                    </div>
                </section>
            </div>
        </div>
    );
}

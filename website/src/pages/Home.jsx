import { Link } from 'react-router-dom';
import Hero from '../components/home/Hero';
import Features from '../components/home/Features';
import Benefits from '../components/home/Benefits';
import UseCases from '../components/home/UseCases';
import ContactForm from '../components/home/ContactForm';

export default function Home() {
    return (
        <div className="bg-gray-50">
            <Hero />

            {/* What is ZFS DAS */}
            <section className="py-20 bg-white">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="lg:grid lg:grid-cols-2 lg:gap-16 items-center">
                        <div className="animate-slide-up">
                            <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl mb-6">
                                What is <span className="text-gradient">macOS ZFS DAS</span>?
                            </h2>
                            <p className="text-lg text-gray-600 mb-6">
                                A comprehensive, production-ready solution for managing ZFS storage on macOS with
                                Direct Attached Storage (DAS). Built for professionals who demand enterprise-grade
                                reliability without the enterprise complexity.
                            </p>
                            <p className="text-lg text-gray-600 mb-6">
                                Unlike traditional macOS storage solutions, ZFS DAS brings advanced features like
                                data integrity verification, instant snapshots, transparent compression, and built-in
                                encryption - all automated and monitored through intuitive tools.
                            </p>
                            <Link to="/getting-started" className="btn btn-primary">
                                Get Started →
                            </Link>
                        </div>
                        <div className="mt-10 lg:mt-0">
                            <div className="bg-gradient-to-br from-primary-50 to-accent-50 rounded-2xl p-8">
                                <img src="/images/pool-diagram.svg" alt="ZFS Pool Architecture" className="w-full" />
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <Features />
            <Benefits />
            <UseCases />

            {/* Quick Start */}
            <section className="py-20 bg-white">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="text-center mb-16">
                        <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl mb-4">
                            Get Started in 3 Simple Steps
                        </h2>
                        <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                            From installation to production in minutes, not hours
                        </p>
                    </div>

                    <div className="grid md:grid-cols-3 gap-8">
                        {[
                            {
                                step: '1',
                                title: 'Install & Verify',
                                description: 'Run our prerequisites checker, install OpenZFS, and verify your system is ready.',
                                link: '/getting-started',
                            },
                            {
                                step: '2',
                                title: 'Create Your Pool',
                                description: 'Use our interactive wizard to configure and create your ZFS pool with encryption.',
                                link: '/wizards/pool-creation',
                            },
                            {
                                step: '3',
                                title: 'Automate & Monitor',
                                description: 'Set up automated maintenance, monitoring, and enjoy peace of mind.',
                                link: '/wizards/swiftbar',
                            },
                        ].map((step) => (
                            <div key={step.step} className="card hover:scale-105 transition-transform">
                                <div className="flex items-center justify-center w-12 h-12 bg-primary-100 text-primary-600 rounded-lg text-xl font-bold mb-4">
                                    {step.step}
                                </div>
                                <h3 className="text-xl font-semibold text-gray-900 mb-3">{step.title}</h3>
                                <p className="text-gray-600 mb-4">{step.description}</p>
                                <Link to={step.link} className="text-primary-600 hover:text-primary-700 font-medium">
                                    Learn more →
                                </Link>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            <ContactForm />
        </div>
    );
}

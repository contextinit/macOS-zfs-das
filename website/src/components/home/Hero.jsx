import { Link } from 'react-router-dom';
import { ArrowRightIcon } from '@heroicons/react/24/outline';
import Button from '../common/Button';

export default function Hero() {
    return (
        <section className="relative bg-gradient-to-br from-primary-600 via-primary-700 to-accent-600 text-white overflow-hidden">
            {/* Animated background pattern */}
            <div className="absolute inset-0 opacity-10">
                <div className="absolute inset-0" style={{
                    backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.4'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
                }} />
            </div>

            <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24 lg:py-32">
                <div className="lg:grid lg:grid-cols-2 lg:gap-12 items-center">
                    {/* Text Content */}
                    <div className="animate-fade-in">
                        <div className="inline-flex items-center px-4 py-2 bg-white/10 backdrop-blur-sm rounded-full text-sm font-medium mb-6">
                            <span className="flex h-2 w-2 relative mr-2">
                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                                <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                            </span>
                            OpenZFS 2.2+ Compatible
                        </div>

                        <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight mb-6">
                            Professional ZFS Storage
                            <span className="block text-accent-300">for macOS</span>
                        </h1>

                        <p className="text-xl text-blue-100 mb-8 max-w-2xl">
                            Enterprise-grade data protection, automated maintenance, and intuitive monitoring
                            for your Direct Attached Storage. Built by professionals, for professionals.
                        </p>

                        <div className="flex flex-col sm:flex-row gap-4">
                            <Link to="/getting-started">
                                <Button size="lg" className="bg-white text-primary-600 hover:bg-gray-50 w-full sm:w-auto">
                                    Get Started
                                    <ArrowRightIcon className="ml-2 h-5 w-5 inline" />
                                </Button>
                            </Link>
                            <Link to="/wizards">
                                <Button size="lg" variant="outline" className="border-white text-white hover:bg-white/10 w-full sm:w-auto">
                                    Interactive Wizards
                                </Button>
                            </Link>
                        </div>

                        {/* Stats */}
                        <div className="mt-12 grid grid-cols-3 gap-8">
                            {[
                                { value: '100%', label: 'Data Integrity' },
                                { value: '24/7', label: 'Monitoring' },
                                { value: '0%', label: 'Downtime' },
                            ].map((stat) => (
                                <div key={stat.label}>
                                    <div className="text-3xl font-bold">{stat.value}</div>
                                    <div className="text-blue-200 text-sm">{stat.label}</div>
                                </div>
                            ))}
                        </div>
                    </div>

                    {/* Hero Illustration */}
                    <div className="mt-12 lg:mt-0 animate-slide-up">
                        <div className="relative">
                            <div className="absolute inset-0 bg-gradient-to-r from-accent-400 to-primary-400 rounded-2xl blur-3xl opacity-30 animate-pulse-slow" />
                            <img
                                src="/images/monitoring-illustration.svg"
                                alt="ZFS Dashboard"
                                className="relative rounded-2xl shadow-2xl"
                            />
                        </div>
                    </div>
                </div>
            </div>

            {/* Wave separator */}
            <div className="absolute bottom-0 left-0 right-0">
                <svg viewBox="0 0 1440 120" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M0 120L60 110C120 100 240 80 360 70C480 60 600 60 720 65C840 70 960 80 1080 80C1200 80 1320 70 1380 65L1440 60V120H1380C1320 120 1200 120 1080 120C960 120 840 120 720 120C600 120 480 120 360 120C240 120 120 120 60 120H0Z" fill="#F9FAFB" />
                </svg>
            </div>
        </section>
    );
}

import {
    ShieldCheckIcon,
    ClockIcon,
    LockClosedIcon,
    CpuChipIcon,
    ChartBarIcon,
    DocumentDuplicateIcon,
    BoltIcon,
    ServerIcon
} from '@heroicons/react/24/outline';
import Card from '../common/Card';

export default function Features() {
    const features = [
        {
            icon: ShieldCheckIcon,
            title: 'Data Integrity',
            description: 'End-to-end checksumming detects and repairs silent data corruption automatically. Every byte verified, every time.',
        },
        {
            icon: ClockIcon,
            title: 'Instant Snapshots',
            description: 'Create point-in-time snapshots instantly with zero performance impact. Rollback to any state in seconds.',
        },
        {
            icon: LockClosedIcon,
            title: 'Native Encryption',
            description: 'AES-256-GCM encryption at the dataset level. Your data stays secure, even if drives are stolen.',
        },
        {
            icon: CpuChipIcon,
            title: 'Smart Compression',
            description: 'Transparent LZ4 compression saves space without sacrificing performance. More storage, less cost.',
        },
        {
            icon: ChartBarIcon,
            title: 'Real-time Monitoring',
            description: 'SwiftBar integration shows pool health, capacity, and errors right in your menu bar. Always informed.',
        },
        {
            icon: BoltIcon,
            title: 'Automated Maintenance',
            description: 'Monthly scrubs, health checks, and email alerts - all automated. Set it and forget it.',
        },
        {
            icon: DocumentDuplicateIcon,
            title: 'RAID-Z Protection',
            description: 'Superior to traditional RAID. Survive multiple disk failures without data loss.',
        },
        {
            icon: ServerIcon,
            title: 'Time Machine Ready',
            description: 'Built-in Time Machine support with network sharing. Perfect for backing up multiple Macs.',
        },
    ];

    return (
        <section id="features" className="py-20 bg-gray-50">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="text-center mb-16">
                    <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl mb-4">
                        Everything You Need, Nothing You Don't
                    </h2>
                    <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                        Professional-grade features that just work, without the enterprise complexity
                    </p>
                </div>

                <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
                    {features.map((feature) => (
                        <Card key={feature.title} className="group">
                            <div className="flex items-center justify-center w-12 h-12 bg-primary-100 text-primary-600 rounded-lg mb-4 group-hover:bg-primary-600 group-hover:text-white transition-colors">
                                <feature.icon className="h-6 w-6" />
                            </div>
                            <h3 className="text-lg font-semibold text-gray-900 mb-2">{feature.title}</h3>
                            <p className="text-gray-600 text-sm">{feature.description}</p>
                        </Card>
                    ))}
                </div>
            </div>
        </section>
    );
}

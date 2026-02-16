import Badge from '../common/Badge';

export default function UseCases() {
    const useCases = [
        {
            title: 'Video Production Studio',
            badge: 'Content Creation',
            description: 'Managing 50TB of 4K footage with instant snapshots before every edit. Compression saves 30% storage without quality loss.',
            stats: ['50TB Pool', '30% Space Saved', 'Zero Data Loss'],
        },
        {
            title: 'Software Development Team',
            badge: 'Development',
            description: 'Entire dev environment backed up with hourly snapshots. Rollback bad database migrations in seconds, not hours.',
            stats: ['10 Developers', 'Hourly Snapshots', 'Instant Rollback'],
        },
        {
            title: 'Photography Archive',
            badge: 'Media Management',
            description: '100,000+ RAW files protected with checksums. Automatic detection of bit rot before photos are corrupted.',
            stats: ['100K+ Photos', 'Zero Corruption', 'Automated Scrub'],
        },
        {
            title: 'Home Media Server',
            badge: 'Home Lab',
            description: 'Plex library with RAID-Z2 protection. Survived two disk failures simultaneously without a single movie lost.',
            stats: ['20TB Media', '2 Disk Failures', 'No Downtime'],
        },
    ];

    return (
        <section className="py-20 bg-gradient-to-br from-gray-50 to-blue-50">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="text-center mb-16">
                    <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl mb-4">
                        Real-World Success Stories
                    </h2>
                    <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                        See how professionals use ZFS DAS to protect what matters
                    </p>
                </div>

                <div className="grid md:grid-cols-2 gap-8">
                    {useCases.map((useCase) => (
                        <div key={useCase.title} className="bg-white rounded-xl shadow-soft p-8 hover:shadow-xl transition-shadow">
                            <Badge variant="primary" className="mb-4">{useCase.badge}</Badge>
                            <h3 className="text-xl font-bold text-gray-900 mb-3">{useCase.title}</h3>
                            <p className="text-gray-600 mb-6">{useCase.description}</p>

                            <div className="flex flex-wrap gap-3">
                                {useCase.stats.map((stat) => (
                                    <div key={stat} className="px-3 py-1 bg-gray-100 rounded-lg text-sm font-medium text-gray-700">
                                        {stat}
                                    </div>
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
}

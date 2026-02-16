import { CheckCircleIcon } from '@heroicons/react/24/solid';

export default function Benefits() {
    const benefits = [
        {
            category: 'For Content Creators',
            items: [
                'Never lose a single frame - comprehensive data protection',
                'Instant snapshots before risky edits',
                'Transparent compression saves valuable storage space',
                'Fast, reliable storage for 4K/8K workflows',
            ],
        },
        {
            category: 'For Developers',
            items: [
                'Git-like snapshots for your entire development environment',
                'Test database changes without fear',
                'Automated backups with Time Machine integration',
                'Lightning-fast builds with compressed storage',
            ],
        },
        {
            category: 'For Media Professionals',
            items: [
                'Protect irreplaceable media assets',
                'Scale storage without losing data',
                'Network Time Machine for team backups',
                'Professional monitoring and alerting',
            ],
        },
        {
            category: 'For Home Lab Enthusiasts',
            items: [
                'Enterprise features without enterprise cost',
                'Learn ZFS without complex setup',
                'Perfect for NAS, media servers, and more',
                'Active community and documentation',
            ],
        },
    ];

    return (
        <section id="about" className="py-20 bg-white">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="text-center mb-16">
                    <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl mb-4">
                        Built for Professionals Who Value Their Data
                    </h2>
                    <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                        Whether you're creating, developing, or managing - ZFS DAS has you covered
                    </p>
                </div>

                <div className="grid md:grid-cols-2 gap-12">
                    {benefits.map((benefit) => (
                        <div key={benefit.category} className="animate-slide-up">
                            <h3 className="text-2xl font-bold text-gray-900 mb-6">{benefit.category}</h3>
                            <ul className="space-y-4">
                                {benefit.items.map((item) => (
                                    <li key={item} className="flex items-start">
                                        <CheckCircleIcon className="h-6 w-6 text-green-500 mr-3 flex-shrink-0 mt-0.5" />
                                        <span className="text-gray-700">{item}</span>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
}

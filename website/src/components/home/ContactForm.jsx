import { useState } from 'react';
import { PaperAirplaneIcon } from '@heroicons/react/24/outline';
import Button from '../common/Button';
import { trackFormSubmit } from '../../utils/analytics';

const TYPE_LABELS = {
    query: 'Question',
    consultation: 'Consultation Request',
    support: 'Technical Support',
    other: 'General Inquiry',
};

const CONTACT_EMAIL = 'info@contextinit.com';

export default function ContactForm() {
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        type: 'query',
        message: '',
        newsletter: false,
    });

    const handleSubmit = (e) => {
        e.preventDefault();

        trackFormSubmit(formData.type, formData.newsletter);

        const subject = encodeURIComponent(
            `[macOS ZFS DAS] ${TYPE_LABELS[formData.type]} from ${formData.name}`
        );
        const body = encodeURIComponent(
            `Name: ${formData.name}\nEmail: ${formData.email}\nType: ${TYPE_LABELS[formData.type]}\n\n${formData.message}${formData.newsletter ? '\n\n[Please add me to the newsletter]' : ''}`
        );

        window.location.href = `mailto:${CONTACT_EMAIL}?subject=${subject}&body=${body}`;
    };

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: type === 'checkbox' ? checked : value,
        }));
    };

    return (
        <section id="contact" className="py-20 bg-white">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="max-w-3xl mx-auto">
                    <div className="text-center mb-12">
                        <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl mb-4">
                            Get in Touch
                        </h2>
                        <p className="text-lg text-gray-600">
                            Have questions? Want a consultation? We're here to help.
                        </p>
                    </div>

                    <form onSubmit={handleSubmit} className="bg-gray-50 rounded-xl p-8">
                        <div className="grid md:grid-cols-2 gap-6 mb-6">
                            <div>
                                <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                                    Name *
                                </label>
                                <input
                                    type="text"
                                    id="name"
                                    name="name"
                                    required
                                    value={formData.name}
                                    onChange={handleChange}
                                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent transition"
                                    placeholder="John Doe"
                                />
                            </div>

                            <div>
                                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                                    Email *
                                </label>
                                <input
                                    type="email"
                                    id="email"
                                    name="email"
                                    required
                                    value={formData.email}
                                    onChange={handleChange}
                                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent transition"
                                    placeholder="john@example.com"
                                />
                            </div>
                        </div>

                        <div className="mb-6">
                            <label htmlFor="type" className="block text-sm font-medium text-gray-700 mb-2">
                                I want to *
                            </label>
                            <select
                                id="type"
                                name="type"
                                value={formData.type}
                                onChange={handleChange}
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent transition"
                            >
                                <option value="query">Ask a question</option>
                                <option value="consultation">Request a consultation session</option>
                                <option value="support">Get technical support</option>
                                <option value="other">Something else</option>
                            </select>
                        </div>

                        <div className="mb-6">
                            <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-2">
                                Message *
                            </label>
                            <textarea
                                id="message"
                                name="message"
                                required
                                rows={5}
                                value={formData.message}
                                onChange={handleChange}
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent transition resize-none"
                                placeholder="Tell us more about your needs..."
                            />
                        </div>

                        <div className="mb-6">
                            <label className="flex items-center">
                                <input
                                    type="checkbox"
                                    name="newsletter"
                                    checked={formData.newsletter}
                                    onChange={handleChange}
                                    className="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
                                />
                                <span className="ml-2 text-sm text-gray-700">
                                    Subscribe to our newsletter for updates and tips
                                </span>
                            </label>
                        </div>

                        <Button
                            type="submit"
                            variant="primary"
                            size="lg"
                            className="w-full"
                        >
                            Send Message
                            <PaperAirplaneIcon className="ml-2 h-5 w-5 inline" />
                        </Button>

                        <p className="mt-4 text-sm text-gray-500 text-center">
                            Clicking "Send Message" will open your email client with the form pre-filled.
                        </p>
                    </form>

                    <p className="text-center text-sm text-gray-500 mt-6">
                        Or email us directly at{' '}
                        <a href={`mailto:${CONTACT_EMAIL}`} className="text-primary-600 hover:text-primary-700 font-medium">
                            {CONTACT_EMAIL}
                        </a>
                    </p>
                </div>
            </div>
        </section>
    );
}

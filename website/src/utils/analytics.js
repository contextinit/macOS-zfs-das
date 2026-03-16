/**
 * Google Analytics 4 — Centralized tracking utilities
 * Measurement ID is read from VITE_GA_ID environment variable.
 *
 * All custom events are routed through the helpers below so that
 * event names/parameters stay consistent and easy to audit.
 *
 * Tracking only fires after the user grants cookie consent
 * (see CookieBanner.jsx / hasConsent()).
 */

const GA_ID = import.meta.env.VITE_GA_ID;

/** Returns true only if the user has explicitly granted analytics consent. */
export function hasConsent() {
    try {
        return localStorage.getItem('analytics_consent') === 'granted';
    } catch {
        return false;
    }
}

/**
 * Dynamically injects the GA script tag and initialises gtag.
 * Called once by CookieBanner when the user accepts cookies.
 */
export function loadAnalytics() {
    if (!GA_ID || document.getElementById('ga-script')) return;
    const script = document.createElement('script');
    script.id = 'ga-script';
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${GA_ID}`;
    document.head.appendChild(script);
    window.gtag('js', new Date());
    window.gtag('config', GA_ID);
}

/* ------------------------------------------------------------------ */
/*  Low-level helpers                                                  */
/* ------------------------------------------------------------------ */

function gtag() {
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push(arguments);
}

/**
 * Send a custom GA4 event.
 * Silently no-ops if gtag.js hasn't loaded (e.g. ad-blockers).
 */
export function trackEvent(eventName, params = {}) {
    if (!hasConsent()) return;
    if (typeof window.gtag === 'function') {
        window.gtag('event', eventName, params);
    }
}

/**
 * SPA page-view — call on every React Router location change.
 */
export function trackPageView(path, title) {
    if (!hasConsent()) return;
    if (typeof window.gtag === 'function') {
        window.gtag('config', GA_ID, {
            page_path: path,
            page_title: title,
        });
    }
}

/* ------------------------------------------------------------------ */
/*  Wizard events                                                      */
/* ------------------------------------------------------------------ */

export function trackWizardStep(wizardName, stepNumber, stepTotal, direction) {
    trackEvent('wizard_step', {
        wizard_name: wizardName,
        step_number: stepNumber,
        step_total: stepTotal,
        direction, // 'next' | 'previous'
    });
}

export function trackWizardComplete(wizardName) {
    trackEvent('wizard_complete', {
        wizard_name: wizardName,
    });
}

export function trackWizardConfig(wizardName, configKey, configValue) {
    trackEvent('wizard_config', {
        wizard_name: wizardName,
        config_key: configKey,
        config_value: String(configValue),
    });
}

/* ------------------------------------------------------------------ */
/*  Copy-to-clipboard                                                  */
/* ------------------------------------------------------------------ */

export function trackCopyCommand(command) {
    trackEvent('copy_command', {
        command_preview: String(command).slice(0, 80),
    });
}

/* ------------------------------------------------------------------ */
/*  Contact form                                                       */
/* ------------------------------------------------------------------ */

export function trackFormSubmit(formType, hasNewsletter) {
    trackEvent('form_submit', {
        form_type: formType,
        has_newsletter: hasNewsletter,
    });
}

/* ------------------------------------------------------------------ */
/*  CTA / navigation                                                   */
/* ------------------------------------------------------------------ */

export function trackCtaClick(ctaText, ctaLocation) {
    trackEvent('cta_click', {
        cta_text: ctaText,
        cta_location: ctaLocation,
    });
}

export function trackDownload(downloadType) {
    trackEvent('download_click', {
        download_type: downloadType,
    });
}

export function trackNavClick(linkName, linkLocation) {
    trackEvent('nav_click', {
        link_name: linkName,
        link_location: linkLocation,
    });
}

export function trackFooterClick(linkName, linkSection) {
    trackEvent('footer_click', {
        link_name: linkName,
        link_section: linkSection,
    });
}

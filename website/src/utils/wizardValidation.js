/**
 * Input validation for wizard fields.
 *
 * These validators mirror the same rules enforced in the shell scripts so
 * that the generated commands are always safe to copy-paste into a terminal.
 */

/** ZFS pool / dataset name: starts with a letter, then letters/digits/hyphens/underscores */
const POOL_NAME_RE = /^[a-zA-Z][a-zA-Z0-9_-]{0,63}$/;

/** macOS disk identifier: diskN or diskNsM */
const DISK_ID_RE = /^disk[0-9]+(s[0-9]+)?$/;

/** Storage quota: digits followed by G, T, or M (case-insensitive) */
const QUOTA_RE = /^[0-9]+[gGtTmM]$/;

/** SMB share name / dataset name: letters, digits, hyphens, underscores */
const SHARE_NAME_RE = /^[a-zA-Z][a-zA-Z0-9_-]{0,79}$/;

export function validatePoolName(value) {
    if (!value) return 'Pool name is required.';
    if (!POOL_NAME_RE.test(value)) {
        return 'Pool name must start with a letter and contain only letters, numbers, hyphens, or underscores (max 64 characters).';
    }
    return null;
}

export function validateDrives(value) {
    const trimmed = value.trim();
    if (!trimmed) return 'At least one drive identifier is required.';
    const ids = trimmed.split(/\s+/);
    const bad = ids.filter(id => !DISK_ID_RE.test(id));
    if (bad.length > 0) {
        return `Invalid drive identifier(s): ${bad.join(', ')}. Expected format: disk2, disk3, disk3s1 etc.`;
    }
    return null;
}

export function validateQuota(value) {
    if (!value) return 'Quota is required.';
    if (!QUOTA_RE.test(value)) return 'Quota must be a number followed by G, T, or M (e.g. 500G, 2T).';
    return null;
}

export function validateShareName(value) {
    if (!value) return 'Share name is required.';
    if (!SHARE_NAME_RE.test(value)) {
        return 'Share name must start with a letter and contain only letters, numbers, hyphens, or underscores (max 80 characters).';
    }
    return null;
}

export function validateDatasetName(value) {
    if (!value) return 'Dataset name is required.';
    if (!POOL_NAME_RE.test(value)) {
        return 'Dataset name must start with a letter and contain only letters, numbers, hyphens, or underscores.';
    }
    return null;
}

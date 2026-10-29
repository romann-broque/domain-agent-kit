/**
 * Shared kernel: value objects that several bounded contexts agree on, and nothing else.
 *
 * <p>Every context may depend on this package. Keep it small: a type belongs here only when two contexts need the
 * same meaning, not merely the same shape. Empty until such a type exists.
 */
package com.example.starter.shared;

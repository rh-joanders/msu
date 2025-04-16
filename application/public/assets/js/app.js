/**
 * Main JavaScript file for PHP Kickstarter Template
 */

// Wait for the DOM to be ready
document.addEventListener('DOMContentLoaded', function() {
    // Initialize the application
    initApp();
    
    // Set up event listeners
    setupEventListeners();
});

/**
 * Initialize the application
 */
function initApp() {
    console.log('PHP Kickstarter Template - App Initialized');
    
    // Example: Set up CSRF token for AJAX requests
    setupCsrfToken();
    
    // Example: Handle flash messages
    handleFlashMessages();
}

/**
 * Set up event listeners
 */
function setupEventListeners() {
    // Example: Handle form submissions
    setupFormSubmissions();
    
    // Example: Handle AJAX links
    setupAjaxLinks();
}

/**
 * Set up CSRF token for AJAX requests
 */
function setupCsrfToken() {
    // Get the CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    
    if (csrfToken) {
        // Add the CSRF token to all AJAX requests
        (function(open) {
            XMLHttpRequest.prototype.open = function(method, url, async, user, pass) {
                open.call(this, method, url, async, user, pass);
                
                if (method.toLowerCase() !== 'get') {
                    this.setRequestHeader('X-CSRF-TOKEN', csrfToken);
                }
            };
        })(XMLHttpRequest.prototype.open);
    }
}

/**
 * Handle flash messages
 */
function handleFlashMessages() {
    // Get all flash messages
    const flashMessages = document.querySelectorAll('.alert');
    
    // Add a close button to each flash message
    flashMessages.forEach(function(message) {
        // Create close button
        const closeButton = document.createElement('button');
        closeButton.innerHTML = '&times;';
        closeButton.className = 'close';
        closeButton.style.float = 'right';
        closeButton.style.background = 'none';
        closeButton.style.border = 'none';
        closeButton.style.fontSize = '20px';
        closeButton.style.fontWeight = 'bold';
        closeButton.style.cursor = 'pointer';
        
        // Add click event to close the message
        closeButton.addEventListener('click', function() {
            message.style.display = 'none';
        });
        
        // Add close button to message
        message.insertBefore(closeButton, message.firstChild);
        
        // Auto-hide message after 5 seconds
        setTimeout(function() {
            message.style.display = 'none';
        }, 5000);
    });
}

/**
 * Set up form submissions
 */
function setupFormSubmissions() {
    // Get all forms with data-ajax attribute
    const ajaxForms = document.querySelectorAll('form[data-ajax="true"]');
    
    ajaxForms.forEach(function(form) {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Get form data
            const formData = new FormData(form);
            
            // Get form action and method
            const action = form.getAttribute('action') || window.location.href;
            const method = form.getAttribute('method') || 'post';
            
            // Send AJAX request
            fetch(action, {
                method: method.toUpperCase(),
                body: formData,
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(response => response.json())
            .then(data => {
                // Handle response
                if (data.redirect) {
                    window.location.href = data.redirect;
                } else if (data.message) {
                    // Create and show message
                    showMessage(data.message, data.status || 'success');
                }
                
                // Call the success callback if defined
                if (window[form.getAttribute('data-success-callback')]) {
                    window[form.getAttribute('data-success-callback')](data);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                
                // Call the error callback if defined
                if (window[form.getAttribute('data-error-callback')]) {
                    window[form.getAttribute('data-error-callback')](error);
                }
            });
        });
    });
}

/**
 * Set up AJAX links
 */
function setupAjaxLinks() {
    // Get all links with data-ajax attribute
    const ajaxLinks = document.querySelectorAll('a[data-ajax="true"]');
    
    ajaxLinks.forEach(function(link) {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Get link href
            const href = link.getAttribute('href');
            
            // Get link method
            const method = link.getAttribute('data-method') || 'get';
            
            // Send AJAX request
            fetch(href, {
                method: method.toUpperCase(),
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(response => response.json())
            .then(data => {
                // Handle response
                if (data.redirect) {
                    window.location.href = data.redirect;
                } else if (data.message) {
                    // Create and show message
                    showMessage(data.message, data.status || 'success');
                }
                
                // Call the success callback if defined
                if (window[link.getAttribute('data-success-callback')]) {
                    window[link.getAttribute('data-success-callback')](data);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                
                // Call the error callback if defined
                if (window[link.getAttribute('data-error-callback')]) {
                    window[link.getAttribute('data-error-callback')](error);
                }
            });
        });
    });
}

/**
 * Show a message
 * 
 * @param {string} message The message to show
 * @param {string} type The message type (success, error, warning, info)
 */
function showMessage(message, type = 'success') {
    // Create message element
    const messageElement = document.createElement('div');
    messageElement.className = 'alert alert-' + type;
    messageElement.innerHTML = message;
    
    // Create close button
    const closeButton = document.createElement('button');
    closeButton.innerHTML = '&times;';
    closeButton.className = 'close';
    closeButton.style.float = 'right';
    closeButton.style.background = 'none';
    closeButton.style.border = 'none';
    closeButton.style.fontSize = '20px';
    closeButton.style.fontWeight = 'bold';
    closeButton.style.cursor = 'pointer';
    
    // Add click event to close the message
    closeButton.addEventListener('click', function() {
        messageElement.style.display = 'none';
    });
    
    // Add close button to message
    messageElement.insertBefore(closeButton, messageElement.firstChild);
    
    // Add message to the body
    document.body.insertBefore(messageElement, document.body.firstChild);
    
    // Auto-hide message after 5 seconds
    setTimeout(function() {
        messageElement.style.display = 'none';
    }, 5000);
}

/**
 * Get data from an API
 * 
 * @param {string} url The API URL
 * @param {object} options Fetch options
 * @returns {Promise} A promise that resolves to the API response
 */
function fetchApi(url, options = {}) {
    // Set default options
    const defaultOptions = {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
        }
    };
    
    // Merge options
    const mergedOptions = { ...defaultOptions, ...options };
    
    // Send request
    return fetch(url, mergedOptions)
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        });
}

/**
 * Validate a form field
 * 
 * @param {HTMLElement} field The field to validate
 * @returns {boolean} True if the field is valid
 */
function validateField(field) {
    // Get validation rules
    const rules = field.getAttribute('data-validate');
    if (!rules) return true;
    
    // Get field value
    const value = field.value;
    
    // Get field name
    const name = field.getAttribute('name');
    
    // Split rules
    const ruleList = rules.split('|');
    
    // Validate each rule
    for (const rule of ruleList) {
        // Check if rule has parameters
        if (rule.includes(':')) {
            const [ruleName, ruleParams] = rule.split(':', 2);
            const params = ruleParams.split(',');
            
            // Validate rule with parameters
            if (!validateRule(ruleName, value, params, name, field)) {
                return false;
            }
        } else {
            // Validate rule without parameters
            if (!validateRule(rule, value, [], name, field)) {
                return false;
            }
        }
    }
    
    return true;
}

/**
 * Validate a field rule
 * 
 * @param {string} rule The rule name
 * @param {string} value The field value
 * @param {array} params The rule parameters
 * @param {string} name The field name
 * @param {HTMLElement} field The field element
 * @returns {boolean} True if the rule is valid
 */
function validateRule(rule, value, params, name, field) {
    switch (rule) {
        case 'required':
            if (!value) {
                setFieldError(field, `${name} is required`);
                return false;
            }
            break;
        case 'min':
            if (value.length < params[0]) {
                setFieldError(field, `${name} must be at least ${params[0]} characters`);
                return false;
            }
            break;
        case 'max':
            if (value.length > params[0]) {
                setFieldError(field, `${name} must be at most ${params[0]} characters`);
                return false;
            }
            break;
        case 'email':
            if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
                setFieldError(field, `${name} must be a valid email`);
                return false;
            }
            break;
        case 'numeric':
            if (!/^\d+$/.test(value)) {
                setFieldError(field, `${name} must be numeric`);
                return false;
            }
            break;
        case 'alpha':
            if (!/^[a-zA-Z]+$/.test(value)) {
                setFieldError(field, `${name} must contain only letters`);
                return false;
            }
            break;
        case 'alphanumeric':
            if (!/^[a-zA-Z0-9]+$/.test(value)) {
                setFieldError(field, `${name} must contain only letters and numbers`);
                return false;
            }
            break;
    }
    
    return true;
}

/**
 * Set a field error
 * 
 * @param {HTMLElement} field The field element
 * @param {string} error The error message
 */
function setFieldError(field, error) {
    // Add error class to field
    field.classList.add('is-invalid');
    
    // Get or create error element
    let errorElement = field.nextElementSibling;
    if (!errorElement || !errorElement.classList.contains('invalid-feedback')) {
        errorElement = document.createElement('div');
        errorElement.className = 'invalid-feedback';
        field.parentNode.insertBefore(errorElement, field.nextSibling);
    }
    
    // Set error message
    errorElement.textContent = error;
}

/**
 * Clear field errors
 * 
 * @param {HTMLElement} field The field element
 */
function clearFieldError(field) {
    // Remove error class
    field.classList.remove('is-invalid');
    
    // Remove error element
    const errorElement = field.nextElementSibling;
    if (errorElement && errorElement.classList.contains('invalid-feedback')) {
        errorElement.remove();
    }
}
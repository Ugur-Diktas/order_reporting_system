const apiUrl = "http://localhost:8080/api/";

async function fetchOrders() {
    try {
        const response = await fetch(`${apiUrl}list_orders`);
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        const orders = await response.json();
        // Process and display orders
    } catch (error) {
        console.error('Failed to fetch orders:', error);
    }
}

async function uploadCSV(file) {
    const formData = new FormData();
    formData.append('csvfile', file);

    try {
        const response = await fetch(`${apiUrl}upload`, {
            method: 'POST',
            body: formData
        });
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        const result = await response.json();
        console.log('File uploaded successfully:', result);
    } catch (error) {
        console.error('Failed to upload file:', error);
    }
}

// Example of handling form submission
document.getElementById('upload-form').addEventListener('submit', function (event) {
    event.preventDefault();
    const fileInput = document.getElementById('file-input');
    if (fileInput.files.length > 0) {
        uploadCSV(fileInput.files[0]);
    }
});

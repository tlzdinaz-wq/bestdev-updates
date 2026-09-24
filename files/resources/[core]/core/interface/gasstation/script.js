function createDigitRoller(elementId) {
    const digitRoller = document.querySelector(`#${elementId} .digit-roller`);
    digitRoller.innerHTML = '';
    
    for (let i = 0; i < 3; i++) { 
        for (let digit = 0; digit <= 9; digit++) {
            const digitElement = document.createElement('div');
            digitElement.className = 'digit';
            digitElement.textContent = digit;
            digitRoller.appendChild(digitElement);
        }
    }
    
    return digitRoller;
}

const priceDigits = ['price-1', 'price-2', 'price-3', 'price-4'];
const fuelDigits = ['fuel-1', 'fuel-2', 'fuel-3'];

const priceRollers = priceDigits.map(createDigitRoller);
const fuelRollers = fuelDigits.map(createDigitRoller);
function rollToDigit(roller, targetDigit, instant = false) {
    const digitHeight = 60;
    const totalDigits = 30;
    const finalPosition = -((totalDigits - 10 + targetDigit) % 10) * digitHeight;

    if (instant) {
        roller.style.transition = 'none';
        roller.style.top = `${finalPosition}px`;
    } else {
        roller.style.transition = 'top 1s cubic-bezier(0.25, 1, 0.5, 1)';
        roller.style.top = `${finalPosition}px`;
    }
}


 
function updateDisplay(price, fuel, instant = false) {
    const priceStr = Math.floor(price).toString().padStart(4, '0');
    const fuelStr = Math.floor(fuel).toString().padStart(3, '0');

    priceDigits.forEach((id, index) => {
        rollToDigit(priceRollers[index], parseInt(priceStr[index]), instant);
    });

    fuelDigits.forEach((id, index) => {
        rollToDigit(fuelRollers[index], parseInt(fuelStr[index]), instant);
    });
}

 
function GetParentResourceName() {
    let resourceName = 'fs_fuel';
    try {
        resourceName = window.GetParentResourceName();
    } catch (e) {
        console.error('Erreur lors de la récupération du nom de la ressource parente:', e);
    }
    return resourceName;
}
 
window.addEventListener('DOMContentLoaded', () => {
    document.body.style.display = 'none';
    
    const urlParams = new URLSearchParams(window.location.search);
    const price = parseFloat(urlParams.get('price')) || 0;
    const fuel = parseFloat(urlParams.get('fuel')) || 0;
     
    updateDisplay(price, fuel);
});
 
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === "updateGasStation") { 
        document.body.style.display = 'block';
        updateDisplay(data.price, data.fuel);
    } else if (data.type === "hideGasStation") { 
        document.body.style.display = 'none';
    }
});
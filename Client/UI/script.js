


/*var testFuncs = {}
var Events = {}

Events.Subscribe = function(name, func) {
    testFuncs[name] = function(...Args) {
        return func(...Args)
    }
}*/

const betframe = document.getElementById("BetFrame");

Events.Subscribe("ShowBetFrame", function(show) {
    if (show) {
        betframe.classList.remove("hidden");
    } else {
        betframe.classList.add("hidden");
    }
})


let betrows = [];

Events.Subscribe("AddBetRow", function(color) {
    let cur_row = betrows.length + 1;

    var row = document.createElement("div");
    row.classList.add("BetRow");

    var betNumber = document.createElement("div");
    betNumber.classList.add("BetNumber");
    betNumber.innerText = cur_row;

    var betColor = document.createElement("div");
    betColor.classList.add("BetColor");
    betColor.style.backgroundColor = color;

    var betAmount = document.createElement("div");
    betAmount.classList.add("BetAmount");
    betAmount.innerText = "Amount : ";

    var betAmountInput = document.createElement("input");
    betAmountInput.classList.add("BetInput");
    betAmountInput.type = "number";
    betAmountInput.min = "0";

    row.appendChild(betNumber);
    row.appendChild(betColor);
    row.appendChild(betAmount);
    row.appendChild(betAmountInput);

    betframe.appendChild(row);

    betAmountInput.addEventListener("change", function() {
        //console.log(cur_row, betAmountInput.value);
        Events.Call("BetSelected", cur_row, betAmountInput.value);
    })

    betrows.push(row);
})

Events.Subscribe("ResetBetRows", function() {
    for (let i = 0; i < betrows.length; i++) {
        betframe.removeChild(betrows[i]);
    }
    betrows = [];
})


/*testFuncs.ShowBetFrame(true);
testFuncs.AddBetRow("#FFFF00");
testFuncs.AddBetRow("#FFFF00");
testFuncs.AddBetRow("#FFFF00");
testFuncs.AddBetRow("#FFFF00");
testFuncs.AddBetRow("#FFFF00");
testFuncs.AddBetRow("#FFFF00");
testFuncs.AddBetRow("#FFFF00");*/

//testFuncs.ResetBetRows();
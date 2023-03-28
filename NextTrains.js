/* Magic Mirror
 * Module: NextTrains
 *
 * By CptMeetKat
 * MIT Licensed.
 */

Module.register("NextTrains", {
    
    trains: [],
    realTimeUpdates: null,
    realTimeTimeStamp: 0,
    welcomeMessage: "Welcome to NextTrains!",
    welcomed: false,
    dbInitialised: false,
    // Default module config.
    defaults: {
        // updateInterval : 10, //Seconds before changeing

        staticInterval: 1800, //30 minutes
        realTimeInterval: 10,

        station: "",
        maxTrains: 4,
        lateCriticalLimit: 600,
        etd: false,
        delaysFormat: "m", //"m, s, m:s"
        debug: false
    },

    start() {

        // this.config.updateInterval = this.config.updateInterval * 1000
        
        let staticInterval = this.config.staticInterval * 1000;
        let realTimeInterval = this.config.realTimeInterval * 1000;

        this.getRealTimeUpdates();
        this.getTrains();


        //Gremlin looking function, refactor pending..
        //Query for database fast
        let cancelInterval2 = setInterval(() => {
            if(this.dbInitialised)
            {
                clearInterval(cancelInterval2);
                setInterval(() => {
                    this.getTrains();
                }, staticInterval);
            }
            else
            {
                this.getTrains();
            }
        }, 10 * 1000);



        setInterval(() => {
            this.getRealTimeUpdates();
        }, realTimeInterval);

    },

    initialMessage() {
        let x = document.createElement("div");
        if(!this.welcomed)
        {
            x.innerHTML = this.welcomeMessage;
            this.welcomed = true;
        }
        else
            x.innerHTML = "Loading...";
        return x
    },


    createDateTimeFromTime(time) {
        let d = new Date()
        let timeAdjusted = time;

        let timeElts = timeAdjusted.split(":");
        let hours = Number.parseInt(timeElts[0]);
        
        //GTFS services may occur at invalid times e.g. 26:30:00  
        if(  hours >= 24  ) 
        {
            hours -= 24;
            d.setDate(d.getDate() + 1);
            timeElts[0] = hours.toString().padStart(2, "0");
            timeAdjusted = timeElts.join(":");
        }

        var datestring = d.getFullYear()  + "-" + ("0"+(d.getMonth()+1)).slice(-2) + "-" + ("0" + d.getDate()).slice(-2)
        return new Date(datestring + "T" + timeAdjusted);
    },

    getDifferenceInMinutes(d1, d2) 
    {

        var diffMs = (d1 - d2); // milliseconds between d1 & d2
        var diffDays = Math.floor(diffMs / 86400000); // days
        var diffHrs = Math.floor((diffMs % 86400000) / 3600000); // hours
        var diffMins = Math.round(((diffMs % 86400000) % 3600000) / 60000); // minutes

        return diffMins+(diffHrs*60)+(24*60*diffDays);
    }, 

    getHeader() {
        return this.name + ": " + this.config.station;
    },

    createTableHeader() {
        let header_row = document.createElement('tr')
        header_row.className = "align-left regular xsmall dimmed"
        
        let header_destination = document.createElement('td')
        let route = document.createElement('td')
        let header_time = document.createElement('td')
        let delay = document.createElement('td')

        
        header_destination.innerText = "Platform"
        route.innerText = "Route"
        header_time.innerText = "Departs"
        delay.innerText = "";
        
        header_row.appendChild(header_destination);
        header_row.appendChild(route);
        header_row.appendChild(header_time);
        header_row.appendChild(delay);
        
        return header_row
    },

    getDelayClass(type)
    {
        let cssClass = "";
        if(type == -1)
            cssClass = "early-mild"
        else if(type == 1)
            cssClass = "late-mild";
        else if(type == 2)
            cssClass = "late-critical";

        return cssClass;
    },

    getDelayFormat(secondsDelayed)
    {
        let delay = document.createElement('td');

        let mins = parseInt(secondsDelayed/60);
        let isMinsNotZero = mins != 0;
        let isSecsNotZero = secondsDelayed != 0;

        if ( this.config.debug && isSecsNotZero) // +m:s (+s)
            delay.innerText = "+" + mins.toString().padStart(2, "0") + ":" + (secondsDelayed%60).toString().padStart(2, "0") + " (+" + secondsDelayed + "s)";
        else if( this.config.delaysFormat == "m:s" && isSecsNotZero) //+m:s
            delay.innerText = "+" + mins.toString().padStart(2, "0") + ":" + (secondsDelayed%60).toString().padStart(2, "0");
        else if( this.config.delaysFormat == "m" && isMinsNotZero)  //+min
            delay.innerText = "+" + mins + "m";
        else if ( this.config.delaysFormat == "s" && isSecsNotZero) // +s
            delay.innerText = "+" + secondsDelayed + "s";

        return delay;
    },


    createTrainRow(destination_name, route_name, departure, secondsDelayed=0, cancelled=false) {
        let row = document.createElement('tr');
        row.className = "align-left small normal";


        let destination = document.createElement('td');
        let route = document.createElement('td');
        let time = document.createElement('td');
        let delay = this.getDelayFormat(secondsDelayed);

        if(cancelled == 1)
            row.classList.add(   "cancelled"   );

        if(delay.innerText != "")
        {
            let classA = this.getDelayClass(this.getDelayType(secondsDelayed));
            if(classA != "")
                row.classList.add(   classA   );
        }


        destination.innerText = destination_name;
        route.innerText = route_name;
        time.innerText = departure;

        row.appendChild(destination);
        row.appendChild(route);
        row.appendChild(time);
        row.appendChild(delay);

        return row;
    },

    generateRealTimeMap() {

        let map = {};

        let arr = this.realTimeUpdates.entity;
        for (let i in arr)
        {
            let tripID = map[arr[i].tripUpdate.trip.tripId];
            if(map[tripID] == undefined)
                map[arr[i].tripUpdate.trip.tripId] = i;
            else
                console.error("Error: multiple IDs found in realtime data");
        }
        return map;
    },

    getDom() {

        if(this.trains.length == 0)
            return this.initialMessage();

        const wrapper = document.createElement("table");
        const header_row = this.createTableHeader();
        wrapper.appendChild(header_row);

        let row = null;
        
        let realTimeMap = this.generateRealTimeMap(this.trains);

        let now = new Date();

        let total = 0;
        let max = this.config.maxTrains;

        this.trains.forEach(t => {

            // Compress this all into some sort of class

            let departureDTPlanned = this.createDateTimeFromTime(t.departure_time);

            if(departureDTPlanned <= now || total >= max)
                return;

            total++;

            
            



            let minsUntilTrain = this.getDifferenceInMinutes(departureDTPlanned, new Date());
            
            let secondsModifier = this.findRealTimeChangesInSeconds(t, realTimeMap);
            let departureTimeActual = departureDTPlanned;
            departureTimeActual.setSeconds(departureTimeActual.getSeconds() + secondsModifier);
            
            let departureTimeActualLocal = departureTimeActual.toLocaleTimeString();
            let delayType = this.getDelayType(secondsModifier);

            let platform = t["stop_name:1"].split(' ').pop();
            let departureDisplay = "";

            if(this.config.debug)
                departureDisplay =  (minsUntilTrain + parseInt(secondsModifier/60))+"m" + " - " + t.departure_time + " (" + departureTimeActualLocal + ")";
            else if(this.config.etd)
                departureDisplay = departureTimeActualLocal;
            else
                departureDisplay = (minsUntilTrain + parseInt(secondsModifier/60))+"m";


            let cancelled = this.isTrainCancelled(t, realTimeMap);
            row = this.createTrainRow( platform, t.trip_headsign, departureDisplay, secondsModifier, cancelled);

            wrapper.appendChild(row)
        });

        return wrapper;
    },

    getDelayType(secondsLate) {
        let type = 0;
        if(secondsLate >= this.config.lateCriticalLimit)
            type = 2;
        else if(secondsLate > 0)
            type = 1;
        else if(secondsLate < -1)
            type = -1;

        return type;
    },

    findRealTimeChangesInSeconds(train, tripIDMap) {
        //This function should be reviewed once cancelled is implemented

        let i = tripIDMap[train.trip_id];
        
        // IF real time updates have not been obtained OR
        // IF the train does not have a corrosponding record in the real time updates
        if (!this.realTimeUpdates || i == undefined) 
            return 0;

        let arr = this.realTimeUpdates.entity;

        let type = arr[i].tripUpdate.trip.scheduleRelationship;

        if(type == undefined || type == "SCHEDULED") 
        {   
            for (let j in arr[i].tripUpdate.stopTimeUpdate) 
            {
                if(arr[i].tripUpdate.stopTimeUpdate[j].stopId == train.stop_id)
                    return arr[i].tripUpdate.stopTimeUpdate[j].departure.delay;
            }
        }

        return 0;
    },



    isTrainCancelled(train, tripIDMap) {

        let i = tripIDMap[train.trip_id];
        
        // IF real time updates have not been obtained OR
        // IF the train does not have a corrosponding record in the real time updates
        if (!this.realTimeUpdates || i == undefined) 
            return 0;

        let arr = this.realTimeUpdates.entity;

        let type = arr[i].tripUpdate.trip.scheduleRelationship;


        if(type == "CANCELED")
        {
            return true;
        }


        return false;
    },


   socketNotificationReceived(notification, payload) {

        if(payload.id != this.identifier)
            return;
        
        console.log(payload);
        if (notification === "STATIC_DATA")
        {
            this.trains = payload.trains;
            this.dbInitialised = true;
        }
        else if(notification === "REALTIME_DATA")
        {
            this.realTimeUpdates = payload.updates;
            this.realTimeTimeStamp = payload.timestamp;
        }
        
        this.updateDom(1000);
    },

    getTrains() {
        Log.info(this.name + ": Getting trains");

        let now = new Date();
        console.log(now.toLocaleTimeString());
        let context = {
            id: this.identifier,
            station: this.config.station,
            // maxTrains: this.config.maxTrains,
            // departedAfter: now.toLocaleTimeString()
            departedAfter: "00:00:00"
        };

        this.sendSocketNotification("GET_TRAINS", {
            context: context 
        });
    },

    getRealTimeUpdates() {
        Log.info(this.name + ": Getting real time updates");

        let context = {
            id: this.identifier,
        };

        this.sendSocketNotification("GET_REALTIME", {
            context: context
        });
    },

    // Define required styles.
    getStyles() {
        return ["nextTrains.css"];
    }

});

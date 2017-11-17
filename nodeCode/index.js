var firebase = require('firebase-admin');
var request = require('request');

var API_KEY = "AAAAU9V9FLM:APA91bGEVrmQjsTIcelZic-tX1yo1RzJ6etk4Do5hunue28UTlFxX4iBCk2MxaQUzAwzFgxArr2za9WuNV0-ZyBh2Q-yFE5jhJ_1BvoMVpW6NtJQyRGeGsr7gQN6hyA7IZrV1fRopl0G";

var serviceAccount = require("./meta.json");

firebase.initializeApp({
	credential: firebase.credential.cert(serviceAccount),
	databaseURL: "https://my-connect-app.firebaseio.com/"
});
ref = firebase.database().ref();

function listenForNotificationRequests() {
  var requests = ref.child('notificationRequests');
  requests.on('child_added', function(requestSnapshot) {
    var request = requestSnapshot.val();
      sendNotificationToUser(
      request.username, 
      request.message,
	request.sender,
      function() {
        requestSnapshot.ref.remove();
      }
    );
  }, function(error) {
    console.error(error);
  });
};

function sendNotificationToUser(username, message, sender, onSuccess) {
  request({
    url: 'https://fcm.googleapis.com/fcm/send',
    method: 'POST',
    headers: {
      'Content-Type' :' application/json',
      'Authorization': 'key='+API_KEY
    },
    body: JSON.stringify({
      notification: {
        title: "Connect App Notification!",
	text: message,
	sender: sender,
	username: username
      },
      to : "/topics/"+username
      //data: {rideInfo: rideinfo}
    })
  }, function(error, response, body) {
    if (error) { console.error(error); }
    else if (response.statusCode >= 400) { 
      console.error('HTTP Error: '+response.statusCode+' - '+response.statusMessage); 
    }
    else {
      onSuccess();
    }
  });
}

// start listening
listenForNotificationRequests();

package com.firefriends.fivefriends;

import android.app.Application;

import com.firebase.client.Firebase;
import com.parse.Parse;
import com.parse.ParseInstallation;

public class MainApplication extends Application {

    @Override
    public void onCreate(){
        super.onCreate();
        Parse.initialize(this, "APPLICATION ID", "CLIENT KEY");
        ParseInstallation.getCurrentInstallation().saveInBackground();
        Firebase.setAndroidContext(this);
    }
}

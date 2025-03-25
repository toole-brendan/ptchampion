import { useState } from "react";
import { useAuth } from "@/hooks/use-auth";
import Navigation from "@/components/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { LogOut, User, MapPin, Shield, Settings } from "lucide-react";

export default function ProfilePage() {
  const { user, logoutMutation, updateLocationMutation } = useAuth();
  const [locationStatus, setLocationStatus] = useState(
    user?.latitude && user?.longitude ? "enabled" : "disabled"
  );
  
  // Handle logout
  const handleLogout = () => {
    logoutMutation.mutate();
  };
  
  // Handle update location
  const handleUpdateLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          updateLocationMutation.mutate({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude
          });
          setLocationStatus("enabled");
        },
        (error) => {
          console.error("Geolocation error:", error);
          setLocationStatus("error");
        }
      );
    } else {
      setLocationStatus("unsupported");
    }
  };
  
  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      {/* Header */}
      <header className="bg-white border-b border-slate-200">
        <div className="container px-4 py-3 mx-auto">
          <h1 className="text-xl font-bold text-primary">Profile</h1>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        <section className="py-6 px-4 lg:px-8">
          <div className="container mx-auto max-w-5xl">
            <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
              <div className="flex flex-col items-center sm:flex-row sm:items-start">
                <div className="w-20 h-20 bg-accent text-white rounded-full flex items-center justify-center text-3xl font-bold mb-4 sm:mb-0 sm:mr-6">
                  {user?.username.charAt(0).toUpperCase()}
                </div>
                <div className="text-center sm:text-left">
                  <h2 className="text-2xl font-bold">{user?.username}</h2>
                  <p className="text-slate-500 mt-1">
                    {locationStatus === "enabled" ? "Location enabled" : "Location disabled"}
                  </p>
                  <div className="mt-4">
                    <Button 
                      variant="destructive"
                      onClick={handleLogout}
                      disabled={logoutMutation.isPending}
                      className="flex items-center"
                    >
                      <LogOut className="h-4 w-4 mr-2" />
                      {logoutMutation.isPending ? "Logging out..." : "Log out"}
                    </Button>
                  </div>
                </div>
              </div>
            </div>
            
            <Tabs defaultValue="settings" className="w-full">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="settings">Settings</TabsTrigger>
                <TabsTrigger value="location">Location</TabsTrigger>
                <TabsTrigger value="privacy">Privacy</TabsTrigger>
              </TabsList>
              
              <TabsContent value="settings">
                <Card>
                  <CardHeader>
                    <CardTitle>Account Settings</CardTitle>
                    <CardDescription>Manage your account preferences</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <Settings className="h-5 w-5 mr-3 text-slate-400" />
                          <div>
                            <div className="font-medium">Measurement Units</div>
                            <div className="text-sm text-slate-500">Imperial (miles, pounds)</div>
                          </div>
                        </div>
                        <Button variant="outline" size="sm">Change</Button>
                      </div>
                      
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <User className="h-5 w-5 mr-3 text-slate-400" />
                          <div>
                            <div className="font-medium">Update Profile</div>
                            <div className="text-sm text-slate-500">Change your username</div>
                          </div>
                        </div>
                        <Button variant="outline" size="sm">Edit</Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </TabsContent>
              
              <TabsContent value="location">
                <Card>
                  <CardHeader>
                    <CardTitle>Location Settings</CardTitle>
                    <CardDescription>Manage location permissions for leaderboards</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <MapPin className="h-5 w-5 mr-3 text-slate-400" />
                          <div>
                            <div className="font-medium">Location Access</div>
                            <div className="text-sm text-slate-500">
                              {locationStatus === "enabled" ? "Enabled for local leaderboards" : 
                               locationStatus === "error" ? "Permission denied" :
                               locationStatus === "unsupported" ? "Not supported by your device" :
                               "Disabled"}
                            </div>
                          </div>
                        </div>
                        <Button 
                          variant={locationStatus === "enabled" ? "outline" : "default"}
                          size="sm"
                          onClick={handleUpdateLocation}
                          disabled={updateLocationMutation.isPending}
                        >
                          {locationStatus === "enabled" ? "Update" : "Enable"}
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </TabsContent>
              
              <TabsContent value="privacy">
                <Card>
                  <CardHeader>
                    <CardTitle>Privacy Settings</CardTitle>
                    <CardDescription>Manage your data and privacy</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <Shield className="h-5 w-5 mr-3 text-slate-400" />
                          <div>
                            <div className="font-medium">Leaderboard Visibility</div>
                            <div className="text-sm text-slate-500">Your name appears on leaderboards</div>
                          </div>
                        </div>
                        <Button variant="outline" size="sm">Change</Button>
                      </div>
                      
                      <div className="flex items-center justify-between">
                        <div className="flex items-start">
                          <LogOut className="h-5 w-5 mr-3 text-red-500 mt-1" />
                          <div>
                            <div className="font-medium">Delete Account</div>
                            <div className="text-sm text-slate-500">Permanently delete your account and all data</div>
                          </div>
                        </div>
                        <Button variant="destructive" size="sm">Delete</Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </TabsContent>
            </Tabs>
          </div>
        </section>
      </main>

      {/* Bottom Navigation */}
      <Navigation active="profile" />
    </div>
  );
}

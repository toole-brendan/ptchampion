import React, { useRef } from 'react';
import { MapContainer, TileLayer, Polyline, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';
import { MapPin } from 'lucide-react';
import HUD from '@/components/workout/HUD';

// Placeholder type for coordinates
type LatLngTuple = [number, number];

interface Coordinate {
  lat: number;
  lng: number;
}

// Create custom colored markers for start and end points
const startIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

const endIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

interface RunningMapProps {
  coordinates: Coordinate[];
  currentPosition: [number, number] | null;
  isActive: boolean;
  isFinished: boolean;
  permissionGranted: boolean;
  geoError: string | null;
  formattedTime: string;
  pace: string;
  distanceMiles: number;
}

export const RunningMap: React.FC<RunningMapProps> = ({
  coordinates,
  currentPosition,
  isActive,
  isFinished,
  permissionGranted,
  geoError,
  formattedTime,
  pace,
  distanceMiles,
}) => {
  const mapRef = useRef<L.Map>(null);
  
  // Get start and end points for markers
  const startPoint = coordinates.length > 0 ? coordinates[0] : null;
  const endPoint = isFinished && coordinates.length > 1 ? coordinates[coordinates.length - 1] : null;

  return (
    <div className="relative h-64 w-full overflow-hidden rounded-md bg-muted md:h-80">
      <MapContainer 
        ref={mapRef}
        center={currentPosition || [51.505, -0.09]} // Default center if no position yet
        zoom={currentPosition ? 16 : 13} // Zoom in more if position known
        scrollWheelZoom={false} // Disable scroll wheel zoom for better UX on page
        style={{ height: "100%", width: "100%" }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {coordinates.length > 0 && (
          <Polyline pathOptions={{ color: 'blue', weight: 4 }} positions={coordinates as unknown as LatLngTuple[]} />
        )}
        {currentPosition && !isFinished && (
          <Marker position={currentPosition as unknown as LatLngTuple}>
            <Popup>Current Location</Popup>
          </Marker>
        )}
        {/* Start marker */}
        {startPoint && (
          <Marker 
            position={[startPoint.lat, startPoint.lng] as unknown as LatLngTuple} 
            icon={startIcon}
          >
            <Popup>Start Point</Popup>
          </Marker>
        )}
        {/* End marker */}
        {endPoint && (
          <Marker 
            position={[endPoint.lat, endPoint.lng] as unknown as LatLngTuple}
            icon={endIcon}
          >
            <Popup>End Point</Popup>
          </Marker>
        )}
      </MapContainer>

      {/* Use the HUD component for running */}
      {isActive && permissionGranted && (
        <HUD 
          repCount={0}
          formattedTime={formattedTime}
          formFeedback={null}
          pace={pace}
          distance={distanceMiles}
          isRunning={true}
        />
      )}
      
      {/* Show overlay if permission denied */} 
      {!permissionGranted && !isActive && (
         <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-black/70 p-4 text-center text-white">
           <MapPin className="mb-2 size-12 text-destructive" />
           <p className="mb-1 font-semibold">Location Access Issue</p>
           <p className="text-sm">{geoError}</p>
         </div>
      )}
    </div>
  );
};
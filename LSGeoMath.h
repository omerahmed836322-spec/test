#pragma once
#include <math.h>
typedef struct { double latitude; double longitude; } LSGeoPoint;
static inline LSGeoPoint LSGeoDestination(LSGeoPoint p,double meters,double heading) {
    double lat=p.latitude*M_PI/180,lon=p.longitude*M_PI/180,b=heading*M_PI/180,d=meters/6371000.0;
    double v=sin(lat)*cos(d)+cos(lat)*sin(d)*cos(b);
    double nlat=asin(fmax(-1,fmin(1,v)));
    double nlon=lon+atan2(sin(b)*sin(d)*cos(lat),cos(d)-sin(lat)*sin(nlat));
    return (LSGeoPoint){nlat*180/M_PI,fmod(nlon*180/M_PI+540,360)-180};
}
static inline double LSGeoDistance(LSGeoPoint a,LSGeoPoint b) {
    double x=(b.latitude-a.latitude)*M_PI/180,y=(b.longitude-a.longitude)*M_PI/180;
    double h=pow(sin(x/2),2)+cos(a.latitude*M_PI/180)*cos(b.latitude*M_PI/180)*pow(sin(y/2),2);
    return 6371000.0*2*asin(sqrt(fmin(1,fmax(0,h))));
}

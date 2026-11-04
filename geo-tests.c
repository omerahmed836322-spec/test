
#include "LSGeoMath.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
 LSGeoPoint bases[]={{0,0},{24.7136,46.6753},{89.9,179.99},{-89.9,-179.99},{45,179.999},{-45,-179.999}};
 double distances[]={0,1,100,5000,50000};
 int cases=0;
 for(int i=0;i<6;i++) for(int j=0;j<5;j++) for(int k=0;k<24;k++) {
  LSGeoPoint p=LSGeoDestination(bases[i],distances[j],k*15);
  assert(isfinite(p.latitude)&&isfinite(p.longitude));
  assert(p.latitude>=-90&&p.latitude<=90&&p.longitude>=-180&&p.longitude<=180);
  assert(fabs(LSGeoDistance(bases[i],p)-distances[j])<0.01);
  assert(fabs(LSGeoDistance(bases[i],p)-LSGeoDistance(p,bases[i]))<0.001);
  cases++;
 }
 assert(LSGeoDistance((LSGeoPoint){0,179.999},(LSGeoPoint){0,-179.999})<225);
 printf("PASS %d geodesic cases plus dateline boundary\n",cases);
}

#ifndef SERIALMSG_H
#define SERIALMSG_H

enum {
  AM_SERIALMSG      = 11,
  SERIALMSG_HEADER  = 0x9F,
};

typedef nx_struct SerialMsg {
  nx_uint8_t  header;
  nx_uint16_t srcid;
  nx_uint16_t sync_p;
  nx_uint16_t temperature;
  nx_uint16_t light;
  nx_bool fire;
  nx_uint8_t rssi;
} SerialMsg;

#endif


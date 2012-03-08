#ifndef DATAMSG_H
#define DATAMSG_H

enum {
  AM_DATAMSG      = 77,
  DATAMSG_HEADER  = 0x70,
};

typedef nx_struct DataMsg {
  nx_uint8_t header;
  nx_uint8_t srcid;
  nx_uint16_t sync_p;
  nx_uint16_t temp;
  nx_uint16_t light;
  nx_bool fire;
} DataMsg;

#endif

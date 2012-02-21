#ifndef MESSAGE_H
#define MESSAGE_H

enum {
  AM_DATAMSG = 9,
  DATAMSG_HEADER = 0x99,
};

typedef nx_struct DataMsg {
  nx_uint8_t srcid;
  nx_uint16_t sync_p;
  nx_uint16_t temp;
  nx_uint16_t avg_temp;
} DataMsg;

#endif

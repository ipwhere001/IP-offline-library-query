#ifndef __IP_H_
#define __IP_H_

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

	typedef struct tag_ip
	{
		uint32_t prefStart[256];
		uint32_t prefEnd[256];
		uint32_t* endArr;
		char** addrArr;
		uint8_t* buffer;
	}geo_ip;

	geo_ip* ip_instance();
	int32_t ip_loadDat(geo_ip* p);
	char* ip_query(geo_ip* p, char* ip);
	long ip_binary_search(geo_ip* p, long low, long high, long k);
	uint32_t ip_ip2long(geo_ip* p, char* addr, uint32_t* prefix);
	uint32_t ip_read_int32(geo_ip* p, uint8_t* buf, int pos);
	uint32_t ip_read_int24(geo_ip* p, uint8_t* buf, int pos);
	char* get_addr(geo_ip* p, uint32_t j);
		;
#ifdef __cplusplus
}
#endif
#endif

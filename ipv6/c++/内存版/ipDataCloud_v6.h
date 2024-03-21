#ifndef __IP_H_
#define __IP_H_

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include "uint128_t.h"

#ifdef __cplusplus
extern "C" {
#endif

	typedef struct tag_ipv6
	{
		uint32_t prefStart[65600];
		uint32_t prefEnd[65600];
		char **endArr;
		char **addrArr;
	}geo_ipv6;

	geo_ipv6* ipv6_instance();
	int32_t ipv6_loadDat(geo_ipv6* p);
	long getPref(char* ip);
	char* ipv6_query(geo_ipv6* p, char *ip);
	long ipv6_binary_search(geo_ipv6* p, long low, long high, uint128_t k);
	uint32_t ipv6_read_int32(geo_ipv6* p, uint8_t *buf, int pos);


#ifdef __cplusplus
}
#endif
#endif

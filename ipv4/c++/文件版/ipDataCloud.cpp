#include "ipDataCloud.h"
#include "string.h"
#include <stdlib.h>

//char* IP_FILENAME = "F:\\ipv4_city.dat";


geo_ip* ip_instance()
{
	geo_ip* ret = (geo_ip*)malloc(sizeof(geo_ip));
	if (ip_loadDat(ret) >= 0)
	{
		return ret;
	}

	if (ret)
	{
		free(ret);
	}
	return NULL;
}

int32_t ip_loadDat(geo_ip* p)
{
	FILE* file;
	
	long len = 0;
	int k, i, j;
	uint32_t RecordSize;
	errno_t err = fopen_s(&file, "your file path", "rb");
	if (err == 2)
	{
		printf("%s", "There is no such file or directory");
		return -2;
	}
	fseek(file, 0, SEEK_END);
	len = ftell(file);
	fseek(file, 0, SEEK_SET);
	p->buffer = (uint8_t*)malloc(len * sizeof(uint8_t));
	fread(p->buffer, 1, len, file);
	fclose(file);

	for (k = 0; k < 256; k++)
	{
		i = k * 8 + 4;
		p->prefStart[k] = ip_read_int32(p, p->buffer, i);
		p->prefEnd[k] = ip_read_int32(p, p->buffer, i + 4);
	}

	RecordSize = ip_read_int32(p, p->buffer, 0);
	p->endArr = (uint32_t*)malloc(RecordSize * sizeof(uint32_t));
	for (i = 0; i < RecordSize; i++)
	{
		j = 2052 + (i * 9);
		p->endArr[i] = ip_read_int32(p, p->buffer, j);
	}
	return 0;
}

char* ip_query(geo_ip* p, char* ip)
{
	uint32_t pref, cur, intIP, low, high;
	if (NULL == p)
	{
		return NULL;
	}
	intIP = ip_ip2long(p, ip, &pref);;
	low = p->prefStart[pref];
	high = p->prefEnd[pref];
	cur = (low == high) ? low : ip_binary_search(p, low, high, intIP);
	if (cur == 100000000) {
		char* nil = (char*)malloc(2 * sizeof(char));
		nil[0] = '|';
		nil[1] = '\0';
		return nil;
	}
	return get_addr(p,cur);
}

long ip_binary_search(geo_ip* p, long low, long high, long k)
{
	long M = 0;
	while (low <= high)
	{
		long mid = (low + high) / 2;

		uint32_t endipNum = p->endArr[mid];
		if (endipNum >= k)
		{
			M = mid;
			if (mid == 0)
			{
				break;
			}
			high = mid - 1;
		}
		else
			low = mid + 1;
	}
	return M;
}

char* get_addr(geo_ip* p, uint32_t j) {
	uint32_t index = 2052 + j * 9;
	uint32_t offset = ip_read_int32(p, p->buffer, index + 4);
	uint32_t length = p->buffer[index + 8];
	char* result = (char*)malloc((length + 1) * sizeof(char));
	memcpy(result, p->buffer + offset, length);
	result[length] = '\0';
	return result;
}

uint32_t ip_ip2long(geo_ip* p, char* addr, uint32_t* prefix)
{
	uint32_t c, octet, t;
	uint32_t ipnum;
	int i = 3;

	octet = ipnum = 0;
	while ((c = *addr++))
	{
		if (c == '.')
		{
			ipnum <<= 8;
			ipnum += octet;
			i--;
			octet = 0;


		}
		else
		{
			t = octet;
			octet <<= 3;
			octet += t;
			octet += t;
			c -= '0';

			octet += c;
			if (i == 3)
			{
				*prefix = octet;
			}
		}
	}

	ipnum <<= 8;

	return ipnum + octet;
}

uint32_t ip_read_int32(geo_ip* p, uint8_t* buf, int pos)
{
	uint32_t result;
	result = (uint32_t)((buf[pos]) | (buf[pos + 1] << 8) | (buf[pos + 2] << 16) | (buf[pos + 3] << 24));
	return result;
}

uint32_t ip_read_int24(geo_ip* p, uint8_t* buf, int pos)
{
	uint32_t result;
	result = (uint32_t)((buf[pos]) | (buf[pos + 1] << 8) | (buf[pos + 2] << 16) | (buf[pos + 3] << 24));
	return result;
}

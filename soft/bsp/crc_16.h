/*
 *      crc16.c
 *
 * This source code is licensed under the GNU General Public License,
 * Version 2. See the file COPYING for more details.
 *
 * took it here https://code.woboq.org/linux/linux/lib/crc16.h.html
 */
#include <stdint.h>

extern uint16_t const crc16_table[256];

static inline uint16_t crc16_byte(uint16_t crc, const uint8_t data)
{
	return (crc >> 8) ^ crc16_table[(crc ^ data) & 0xff];
}

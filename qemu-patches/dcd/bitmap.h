#ifndef CXL_BIT_MAP_H_H
#define CXL_BIT_MAP_H_H

struct bitmap{
	uint8_t* bits;
	uint64_t size;
	int (*check_bit)(struct bitmap *bm, uint64_t pos);
	int (*set_bit)(struct bitmap *bm, uint64_t pos);
	int (*clear_bit)(struct bitmap *bm, uint64_t pos);
};

static int bitmap_check_bit(struct bitmap *bm, uint64_t pos){
	uint8_t offset = 0;

	if (pos >= bm->size)
		return -1;

	offset=pos & 0xff;
	pos = pos/8;

	return (bm->bits[pos]>>offset) & 0x1;
}

static int bitmap_set_bit(struct bitmap *bm, uint64_t pos){
	uint8_t offset = 0;

	if (pos >= bm->size)
		return -1;

	offset=pos & 0xff;
	pos = pos/8;

	bm->bits[pos] |= (1<<offset);

	return 0;
}

static int bitmap_clear_bit(struct bitmap *bm, uint64_t pos){
	uint8_t offset = 0;

	if (pos >= bm->size)
		return -1;

	offset=pos & 0xff;
	pos = pos/8;

	bm->bits[pos] &= ~(1<<offset);

	return 0;
}

static struct bitmap* init_bitmap(uint64_t size){
	struct bitmap *bm;
	int len = (size-1)/8+1;

	bm = g_malloc(sizeof(struct bitmap));
	if (!bm)
		return NULL;

	bm->bits = g_malloc(len);
	if (!bm->bits) {
		g_free(bm);
		return NULL;
	}
	
	bm->size = size;
	bm->check_bit = bitmap_check_bit;
	bm->set_bit = bitmap_check_bit;
	bm->clear_bit = bitmap_clear_bit;
	
	return bm;
}

static void destroy_bitmap(struct bitmap *bm){
	if (bm){
		g_free(bm->bits);
		g_free(bm);
	}
}
#endif

using uint8 = unsigned char;
using uint32 = unsigned int;
constexpr uint8 INVENTORY_SLOT_BAG_START=19, INVENTORY_SLOT_BAG_END=23, INVENTORY_SLOT_BAG_0=255;
constexpr uint8 EQUIPMENT_SLOT_END=19, INVENTORY_SLOT_ITEM_START=23;
struct Player { uint8 count; uint8 GetInventorySlotCount() const { return count; } };
struct Item { uint8 bag,slot; Player* owner; uint8 GetBagSlot() const { return bag; } uint8 GetSlot() const { return slot; } Player* GetOwner() const { return owner; } bool IsInInventoryOrEquipment() const; };
bool Item::IsInInventoryOrEquipment() const
{
    uint8 const bag = GetBagSlot();
    if (bag >= INVENTORY_SLOT_BAG_START && bag < INVENTORY_SLOT_BAG_END)
        return true;
    if (bag != INVENTORY_SLOT_BAG_0)
        return false;
    if (GetSlot() < EQUIPMENT_SLOT_END)
        return true;
    Player const* owner = GetOwner();
    return owner && GetSlot() >= INVENTORY_SLOT_ITEM_START
        && uint32(GetSlot()) < uint32(INVENTORY_SLOT_ITEM_START) + owner->GetInventorySlotCount();
}
int main() {
 Player p{16};
 struct Case { unsigned char bag,slot; bool expected; } cases[] = {
 {255,0,true},{255,18,true},{255,19,false},{255,22,false},
 {255,23,true},{255,38,true},{255,39,false},{255,50,false},
 {255,51,false},{255,79,false},{255,86,false},{255,98,false},
 {255,196,false},{19,0,true},{22,31,true},{23,0,false},
 {79,0,false},{85,0,false},{98,0,false},{196,0,false}};
 for (Case c : cases) if (Item{c.bag,c.slot,&p}.IsInInventoryOrEquipment()!=c.expected) return 1;
 if (Item{255,23,nullptr}.IsInInventoryOrEquipment()) return 2;
 p.count=28; if (!Item{255,50,&p}.IsInInventoryOrEquipment() || Item{255,51,&p}.IsInInventoryOrEquipment()) return 3;
 return 0;
}

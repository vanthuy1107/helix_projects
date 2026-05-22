# BUG-037: Param {{pickup_warehouse}}

- **Source**: `projects/mondelez/Edit UX_UI_MDLZ.xlsx` — sheet `Tỷ lệ Đáp ứng & Tuân thủ (234)` row 7
- **Reporter**: Thanh
- **Tenant**: MDLZ
- **Area**: VFR
- **Severity**: Sev2
- **Priority**: **Major** — Lỗi chức năng lớn — không có cách khắc phục tạm thời
- **Triage confidence**: High
- **View**: Tỷ lệ Đáp ứng & Tuân thủ (234)
- **Tech layer**: `backend-config` — JSON QueryConfig / Dynamic Query param template (no code change)
- **Owner team**: `dev-be` — Backend Developer (.NET, EF Core, Dynamic Query)

## Repro steps (best-effort từ raw text)
1. Mở dashboard view: Tỷ lệ Đáp ứng & Tuân thủ (234)
2. Quan sát Param {{pickup_warehouse}}
3. So sánh hành vi hiện tại vs mong muốn

## Expected
có dấu nháy cho từng value

 -- Kho lấy hàng
    AND if(
        arraySort(['Kho trong - BKD','Kho trong - NKD','Kho Hủy - BKD','Kho Hủy - NKD','Kho BEE_BKD','Kho ngoài - NKD','Kho ngoài 2 - NKD','KHO ICD_12','Kho Bao Bì & Nguyên Vật Liệu']) = (
            SELECT arraySort(groupArray(DISTINCT ten_he_thong))
            FROM analytics_workspace.mv_masterdata_kho_stm
        ),
        1 = 1,
        t.diem_nhan IN ('Kho trong - BKD','Kho trong - NKD','Kho Hủy - BKD','Kho Hủy - NKD','Kho BEE_BKD','Kho ngoài - NKD','Kho ngoài 2 - NKD','KHO ICD_12','Kho Bao Bì & Nguyên Vật Liệu')

## Actual (current)
Truyền chưa đúng, các value không có dấu nháy phân tách

 -- Kho lấy hàng
    AND if(
        arraySort(['Kho trong - BKD,Kho trong - NKD,Kho Hủy - BKD,Kho Hủy - NKD,Kho BEE_BKD,Kho ngoài - NKD,Kho ngoài 2 - NKD,KHO ICD_12,Kho Bao Bì & Nguyên Vật Liệu']) = (
            SELECT arraySort(groupArray(DISTINCT ten_he_thong))
            FROM analytics_workspace.mv_masterdata_kho_stm
        ),
        1 = 1,
        t.diem_nhan IN ('Kho trong - BKD,Kho trong - NKD,Kho Hủy - BKD,Kho Hủy - NKD,Kho BEE_BKD,Kho ngoài - NKD,Kho ngoài 2 - NKD,KHO ICD_12,Kho Bao Bì & Nguyên Vật Liệu')

## Note nội bộ
—

## DEV note
—

## Status trong source
`New`

## Raw quote
> **Param {{pickup_warehouse}}**
> Hiện tại: Truyền chưa đúng, các value không có dấu nháy phân tách

 -- Kho lấy hàng
    AND if(
        arraySort(['Kho trong - BKD,Kho trong - NKD,Kho Hủy - BKD,Kho Hủy - NKD,Kho BEE_BKD,Kho ngoài - NKD,Kho ngoài 2 - NKD,KHO ICD_12,Kho Bao Bì & Nguyên Vật Liệu']) = (
            SELECT arraySort(groupArray(DISTINCT ten_he_thong))
            FROM analytics_workspace.mv_masterdata_kho_stm
        ),
        1 = 1,
        t.diem_nhan IN ('Kho trong - BKD,Kho trong - NKD,Kho Hủy - BKD,Kho Hủy - NKD,Kho BEE_BKD,Kho ngoài - NKD,Kho ngoài 2 - NKD,KHO ICD_12,Kho Bao Bì & Nguyên Vật Liệu')
> Mong muốn: có dấu nháy cho từng value

 -- Kho lấy hàng
    AND if(
        arraySort(['Kho trong - BKD','Kho trong - NKD','Kho Hủy - BKD','Kho Hủy - NKD','Kho BEE_BKD','Kho ngoài - NKD','Kho ngoài 2 - NKD','KHO ICD_12','Kho Bao Bì & Nguyên Vật Liệu']) = (
            SELECT arraySort(groupArray(DISTINCT ten_he_thong))
            FROM analytics_workspace.mv_masterdata_kho_stm
        ),
        1 = 1,
        t.diem_nhan IN ('Kho trong - BKD','Kho trong - NKD','Kho Hủy - BKD','Kho Hủy - NKD','Kho BEE_BKD','Kho ngoài - NKD','Kho ngoài 2 - NKD','KHO ICD_12','Kho Bao Bì & Nguyên Vật Liệu')
> Note: 

## Next
Handoff `/qa-executor` — formal bug report + repro env capture (browser, account, tenant connection).

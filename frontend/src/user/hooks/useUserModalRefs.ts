import {useCallback, useRef} from "react";
import type {UserDetailModalRef} from "../components/UserDetailModal";

export function useUserModalRefs() {
    const detailModalRef = useRef<UserDetailModalRef>(null);

    const openDetail = useCallback((id: number): void => {
        detailModalRef.current?.openDetail(id);
    }, []);

    return {detailModalRef, openDetail};
}

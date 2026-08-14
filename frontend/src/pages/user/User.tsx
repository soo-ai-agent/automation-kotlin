import UserTable from "../../components/data_table/UserTable";
import UserToolbar from "../../components/data_table/UserToolbar";
import UserDetailModal from "../../components/modal/UserDetailModal";
import {useUsers} from "../../hooks/useUsers";

const User = () => {
    const {table, modalRefs} = useUsers();

    return (
        <main>
            <h1>사용자</h1>

            <UserToolbar
                selectedCount={table.selectedIds.length}
                isLoading={table.isLoading}
                isDeleting={table.isDeleting}
                reloadUsers={table.reloadUsers}
                deleteSelected={table.deleteSelected}
            />

            <UserTable
                users={table.users}
                isLoading={table.isLoading}
                listState={table.listState}
                selectedIds={table.selectedIds}
                isAllSelected={table.isAllSelected}
                isDeleting={table.isDeleting}
                toggleSelect={table.toggleSelect}
                toggleSelectAll={table.toggleSelectAll}
                openDetail={table.openDetail}
                reloadUsers={table.reloadUsers}
                deleteOne={table.deleteOne}
            />

            <UserDetailModal ref={modalRefs.detailModalRef} />
        </main>
    );
};

export default User;

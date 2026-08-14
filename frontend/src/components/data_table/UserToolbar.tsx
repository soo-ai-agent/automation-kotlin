
type UserToolbarProps = {
    selectedCount: number;
    isLoading: boolean;
    isDeleting: boolean;
    reloadUsers: () => Promise<void>;
    deleteSelected: () => Promise<void>;
};

function UserToolbar({selectedCount, isLoading, isDeleting, reloadUsers, deleteSelected}: UserToolbarProps) {
    return (
        <div>
            <span>선택 {selectedCount}건</span>
            <button type="button" disabled={isDeleting} onClick={() => void deleteSelected()}>
                선택 삭제
            </button>
            <button type="button" disabled={isLoading} onClick={() => void reloadUsers()}>
                새로고침
            </button>
        </div>
    );
}

export default UserToolbar;
